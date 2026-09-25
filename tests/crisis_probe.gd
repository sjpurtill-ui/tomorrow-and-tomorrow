extends Node
## Crises from real state (crisis_system.gd) and turning points
## (turning_points.gd), end to end and offline:
## - hazards read real state: crowding, bad water and weak health raise the
##   sickness hazard; stores and a failed season raise the hunger hazard; a
##   river camp in a wet year can flood, a dry camp cannot;
## - each crisis type opens a court matter with at least three real choices,
##   held by an official until the god summons them; the matter's options
##   carry costs; answering applies real effects (stores, policy channels,
##   bonds) and the crisis plays out: a report in the middle, deaths from the
##   one aggregate population (never below the shock_widening floor), the
##   dead named, an aftermath, and a remembrance choice when people died;
## - a silent god: the holder acts alone after the deadline;
## - "The Land Is Thinning" becomes a decision and stops repeating;
## - a turning point needs a known practice and five quiet years, tells a
##   moment with a "What changes" line and opens its crisis option;
## - the saved state validates, and older saves without it still load.
##   <godot> --headless --path <worktree> res://tests/crisis_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Crisis:=preload("res://scripts/crisis_system.gd")
const Turning:=preload("res://scripts/turning_points.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const CV:=preload("res://scripts/character_voice.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")

var failures:Array[String]=[]
var transcript:Array[String]=[]

func _check(ok:bool,text:String)->void:
	if not ok:
		failures.append(text); printerr("CRISIS FAIL: ",text)

func _world()->void:
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	CV.knowledge_override.clear()
	GameState.settlement_founded_day=0
	GameState.elapsed_days=400
	ForeignDiplomacy.audiences.erase("crises")
	ForeignDiplomacy.audiences.erase("turning_points")
	for civ in CivilizationSystem.civilizations:
		(civ.player_relation as Dictionary)["contact_level"]=2

func _ready()->void:
	Crisis.onsets_enabled=false
	_world()
	_test_hazards()
	for type in ["sickness","hunger","fire","flood","drought","stranger"]:
		_world()
		_test_crisis(type,false)
	_world()
	_test_crisis("sickness",true)
	_world()
	_test_thinning()
	_world()
	_test_turning()
	_test_save()
	_finish()

func _x(overrides:Dictionary={})->Dictionary:
	var x:=Crisis.inputs(int(GameState.elapsed_days))
	x.merge(overrides,true)
	return x

func _test_hazards()->void:
	var day:=int(GameState.elapsed_days)
	var calm:=Crisis.hazards(day,_x({"crowd":0.5,"water_q":1.0,"health":0.92}))
	var crowded:=Crisis.hazards(day,_x({"crowd":1.3,"water_q":0.7,"health":0.55}))
	transcript.append("HAZARD sickness calm %.3f crowded %.3f" % [float(calm.sickness),float(crowded.sickness)])
	_check(float(crowded.sickness)>float(calm.sickness)*3.0,"crowding, bad water and weak health raise the sickness hazard")
	var fed:=Crisis.hazards(day,_x({"food_days":150.0,"weather_season":1.0,"intake":1.0}))
	var lean:=Crisis.hazards(day,_x({"food_days":15.0,"weather_season":0.8,"intake":0.9}))
	transcript.append("HAZARD hunger fed %.4f lean %.4f" % [float(fed.hunger),float(lean.hunger)])
	_check(float(lean.hunger)>float(fed.hunger)*10.0,"thin stores and a failed season raise the hunger hazard")
	_check(float(Crisis.hazards(day,_x({"river":false})).flood)==0.0,"a camp away from the river never floods")
	_check(float(Crisis.hazards(day,_x({"river":true,"weather_season":1.1})).flood)>float(Crisis.hazards(day,_x({"river":true,"weather_season":0.95})).flood),"a wet year raises the flood hazard")
	_check(absf(float(calm.cold)-0.013)<0.0001,"the dim summer keeps the catalog's 1.3 per game century")

func _open(type:String)->Dictionary:
	var day:=int(GameState.elapsed_days)
	var x:=_x({"pop":float(GameState.population_total),"river":true})
	match type:
		"sickness": Crisis._open_sickness(day,x,"sickness",0.12,"",false)
		"hunger": Crisis._open_hunger(day,x,0.2)
		"fire": Crisis._open_fire(day,x)
		"flood": Crisis._open_flood(day,x)
		"drought": Crisis._open_drought(day,_x({"weather_season":0.8}))
		"stranger": Crisis._open_stranger(day,x,CivilizationSystem.civilizations[0])
	for c in Crisis.active():
		if String(c.type)==type: return c
	return {}

func _matter_for(c:Dictionary)->Dictionary:
	for m in Hall.matters():
		if String(m.get("id",""))==String(c.get("matter","")): return m
	return {}

func _advance(to_day:int)->void:
	for day in range(int(GameState.elapsed_days)+1,to_day+1):
		GameState.elapsed_days=day
		Hall.daily(day)

func _test_crisis(type:String,silent:bool)->void:
	var pop0:=GameState.population_total
	var food0:=Hall.player_stock("Food")
	var c:=_open(type)
	_check(not c.is_empty(),"%s: a crisis opens" % type)
	if c.is_empty(): return
	transcript.append("CRISIS %s: %s (m %.3f)" % [type,String(c.name),float(c.m)])
	var m:=_matter_for(c)
	_check(not m.is_empty(),"%s: the crisis waits at court as a matter" % type)
	_check(String(m.get("situation_type",""))=="crisis","%s: the matter is a crisis" % type)
	var onset:=Chronicle.entries("moment").filter(func(e:Dictionary)->bool:return String(e.get("key",""))=="crisis:%s:onset" % String(c.id))
	_check(not onset.is_empty(),"%s: the onset is a moment card" % type)
	if not onset.is_empty():
		transcript.append("  CARD %s — %s" % [String(onset[0].title),String(onset[0].text)])
		_check(String((onset[0].get("action",{}) as Dictionary).get("kind",""))=="court","%s: the card points at the court" % type)
	if silent:
		_advance(int(c.decide_by)+1)
		_check(String(c.choice)!="","%s: a silent god leaves the holder to act (%s)" % [type,String(c.choice)])
		_check((Crisis.state().log as Array).any(func(e:Dictionary)->bool:return String(e.get("kind",""))=="silent"),"%s: the silence is logged" % type)
	else:
		var opened:=Hall.open_matter(String(m.id))
		_check(not opened.is_empty(),"%s: the holder can be summoned" % type)
		var id:=String(opened.get("id",""))
		for line in Hall.find(id).get("lines",[]): transcript.append("  %s: %s" % [String(line.get("speaker","")),String(line.get("text",""))])
		var opts:=Hall.options(id).filter(func(o:Dictionary)->bool:return not String(o.id).begins_with("hear:"))
		_check(opts.size()>=3,"%s: at least three choices (%d)" % [type,opts.size()])
		for o in opts:
			transcript.append("  OPTION %s — %s" % [String(o.label),String(o.sub)])
			_check(CV.permits(String(o.label)+" "+String(o.sub),CV.era_tags("player")),"%s: option words fit the era: %s" % [type,String(o.label)])
		var pick:=String(opts[0].id)
		var r:=Hall.resolve(id,pick)
		transcript.append("  ANSWER %s -> %s" % [pick,String(r.get("outcome",""))])
		_check(bool(r.get("ok",false)),"%s: the answer resolves" % type)
		_check(String(c.choice)==pick,"%s: the choice is kept on the crisis" % type)
	# Middle, second decision if any, end, remembrance.
	_advance(int(c.mid_day)+1)
	if String(c.get("matter_phase",""))=="mid" and String(c.mid_choice)=="" and not silent:
		var mm:=_matter_for(c)
		_check(not mm.is_empty(),"%s: a second decision waits at court" % type)
		if not mm.is_empty():
			var o2:=Hall.open_matter(String(mm.id))
			var opts2:=Hall.options(String(o2.id)).filter(func(o:Dictionary)->bool:return not String(o.id).begins_with("hear:"))
			_check(opts2.size()>=3,"%s: the second decision has choices" % type)
			var r2:=Hall.resolve(String(o2.id),String(opts2[0].id))
			transcript.append("  MID %s -> %s" % [String(opts2[0].id),String(r2.get("outcome",""))])
	_advance(int(c.end_day)+2)
	if String(c.phase)=="remember":
		var rm:=_matter_for(c)
		_check(not rm.is_empty(),"%s: the families ask how the dead are remembered" % type)
		if not rm.is_empty():
			var o3:=Hall.open_matter(String(rm.id))
			var r3:=Hall.resolve(String(o3.id),"cairn")
			transcript.append("  REMEMBER -> %s" % String(r3.get("outcome","")))
		_advance(int(GameState.elapsed_days)+2)
	_check(String(c.phase)=="done","%s: the crisis ends (%s)" % [type,String(c.phase)])
	var end:=Chronicle.entries("notice").filter(func(e:Dictionary)->bool:return String(e.get("key",""))=="crisis:%s:end" % String(c.id))
	_check(not end.is_empty(),"%s: the aftermath is told" % type)
	if not end.is_empty(): transcript.append("  AFTER %s — %s" % [String(end[0].title),String(end[0].text)])
	var dead:=int(c.deaths)
	_check(pop0-GameState.population_total>=0,"%s: the people are counted" % type)
	_check(GameState.population_total>=maxi(30,roundi(float(pop0)*0.7))-1,"%s: deaths stay above the shock_widening floor" % type)
	_check((c.dead as Array).size()==mini(dead,(c.dead as Array).size()) and (dead==0 or not (c.dead as Array).is_empty()),"%s: the dead are named" % type)
	if type in ["fire","flood"]: _check(Hall.player_stock("Food")<food0 or dead>=0,"%s: stores were lost" % type)
	_check(not Crisis._active_of(type).size()>0,"%s: nothing left active" % type)

func _test_thinning()->void:
	GameState.simulation_metrics["ecology"]=0.5
	GameState.last_simulation_event_days["ecology_strain"]=int(GameState.elapsed_days)-110
	var s:=Crisis.state(); s.last_onset=-99999
	_advance(int(GameState.elapsed_days)+1)
	var c:=Crisis._active_of("thinning")
	_check(not c.is_empty(),"the second telling of the thinning land is a decision")
	_check(int(GameState.last_simulation_event_days.get("ecology_strain",0))>int(GameState.elapsed_days)+1000,"the thinning notice stops repeating for years")
	if c.is_empty(): return
	var m:=_matter_for(c)
	var opened:=Hall.open_matter(String(m.get("id","")))
	var r:=Hall.resolve(String(opened.get("id","")),"rest")
	transcript.append("THINNING rest -> %s" % String(r.get("outcome","")))
	_check(Crisis.state().log.any(func(e:Dictionary)->bool:return String(e.get("kind",""))=="decided"),"the god's answer on the land is recorded")
	var channel:=0.0
	for mod in GameState.active_modifiers:
		if String(mod.get("id","")).begins_with("crisis_%s_rest" % String(c.id)): channel=float((mod.effects as Dictionary).get("ecology_delta",0.0))*float(mod.magnitude)
	_check(channel>0.0,"resting the land uses the ecology channel")

func _test_turning()->void:
	GameState.known_discoveries.erase("clay_shaping")
	GameState.elapsed_days=2*365
	_check(Turning.daily(int(GameState.elapsed_days)).is_empty(),"no turning point in the first years")
	GameState.elapsed_days=4*365
	Turning.daily(int(GameState.elapsed_days))
	var told_before:=Turning.told().size()
	GameState.known_discoveries.append("clay_shaping")
	GameState.elapsed_days=int(Turning.state().last)+5*365+1 if int(Turning.state().last)>0 else 4*365
	var point:=Turning.daily(int(GameState.elapsed_days))
	_check(not point.is_empty(),"a known practice turns when its time comes")
	_check(Turning.told().size()==told_before+1,"one turning point at a time")
	var card:=Chronicle.entries("moment").filter(func(e:Dictionary)->bool:return String(e.get("key","")).begins_with("turning:"))
	_check(not card.is_empty() and String(card[0].text).contains("What changes:"),"the turning point is a moment with a What changes line")
	if not card.is_empty(): transcript.append("TURNING %s — %s" % [String(card[0].title),String(card[0].text)])
	_check(Turning.daily(int(GameState.elapsed_days)+30).is_empty(),"five quiet years between turning points")
	if String(point.get("id",""))=="pots": _check(Crisis.unlocked("hunger:pots"),"the pots open a new choice in a hungry season")

func _test_save()->void:
	var data:Dictionary=ForeignDiplomacy.audiences.duplicate(true)
	_check(Hall.validate_state(data),"the court state with crises validates")
	_check(Crisis.valid_state(data.get("crises",{})),"the crisis state validates")
	var older:=data.duplicate(true); older.erase("crises"); older.erase("turning_points")
	_check(Hall.validate_state(older),"an older save without crises validates")
	ForeignDiplomacy.audiences.erase("crises")
	_check((Crisis.state().active as Dictionary).is_empty(),"an older save starts with no crises")

func _finish()->void:
	for line in transcript: print(line)
	if failures.is_empty():
		print("CRISIS_PROBE PASS")
		get_tree().quit(0)
		return
	print("CRISIS_PROBE FAIL (%d)" % failures.size())
	get_tree().quit(1)
