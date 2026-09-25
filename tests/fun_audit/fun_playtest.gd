extends Node
## FUN AUDIT harness (uncommitted, read-only audit). Runs the real game scene
## through the same advance_world_time/_commit_world_day path, answers envoys
## like a plausible player, and logs everything the player would be told.
## Requires the worktree override.cfg (isolated userdata). Never saves.
##   <godot> --headless --path <worktree> res://tests/fun_audit/fun_playtest.tscn -- --years=30 --seed=424242 --out=<file> [--policy=random|heuristic]
## --policy=random (default) answers every audience at random among the enabled
## options. --policy=heuristic reads only what the player is shown: the tone of
## each answer, a stated cost or string, a court member's objection or support,
## and the tells of a bluff, and picks the answer a careful player would.
const Hall:=preload("res://scripts/audience_hall.gd")

class QuietPopup extends CanvasLayer:
	var closing:=false
	var log:Array=[]
	func enqueue(events:Array[Dictionary])->void:
		for e in events:log.append({"day":int(GameState.elapsed_days),"name":String(e.get("name",e.get("id","")))})
	func close()->void:pass

var out:FileAccess
var terrain:Node
var quiet:QuietPopup
var seen_events:Dictionary={}
var seen_inbox:Dictionary={}
var seen_chron:Dictionary={}
var seen_feed:Dictionary={}
var last_status:=""
var rng:=RandomNumberGenerator.new()
var counts:Dictionary={}
var seen_matters:Dictionary={}
var handled_audiences:Dictionary={}
var known_logged:Dictionary={}
const UiMeasure:=preload("res://tests/fun_audit/ui_measure.gd")
var founded_day:=-1
var first_ten:Dictionary={"max_surface":0,"auto_docks":[],"rail_max":0,"kpi_max":0,"dock_tiles_max":0}
var ui_marks:Dictionary={}
## Generational aims (scripts/legacy_aims.gd), when this build has them.
const AIMS_PATH:="res://scripts/legacy_aims.gd"
var aims:GDScript
var aim_policy:="player"
var aim_due:Dictionary={}
var aim_logged:Dictionary={}
var policy:="random"

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f

func w(kind:String,data:Dictionary)->void:
	data["t"]=kind;data["day"]=int(GameState.elapsed_days)
	out.store_line(JSON.stringify(data))
	counts[kind]=int(counts.get(kind,0))+1

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("Tests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	var years:=float(_arg("years","30"))
	var seed_value:=int(_arg("seed","424242"))
	var ambition:=_arg("ambition","makers")
	policy=_arg("policy","random")
	rng.seed=seed_value
	aim_policy=_arg("aims","player")
	if ResourceLoader.exists(AIMS_PATH): aims=load(AIMS_PATH) as GDScript
	out=FileAccess.open(_arg("out","user://fun_playtest.jsonl"),FileAccess.WRITE)
	GameState.reset_for_new_world(seed_value)
	DiscoverySystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	var t0:=Time.get_ticks_msec()
	terrain=load("res://local_terrain.tscn").instantiate();add_child(terrain)
	await get_tree().process_frame;await get_tree().process_frame
	w("boot",{"ms":Time.get_ticks_msec()-t0,"ambition_panel":is_instance_valid(PeopleDirection.panel),"ambitions":PeopleDirection.AMBITIONS.keys().size()})
	PeopleDirection.choose(ambition)
	if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
	await get_tree().process_frame
	w("after_ambition",{"speed":terrain.game_speed,"focus":GameState.founding_focus,"journey":GameState.founding_journey.get("duration_days",-1)})
	quiet=QuietPopup.new();terrain.hud.add_child(quiet);terrain.hud.set_meta("discovery_popup",quiet)
	if PeopleDirection.has_signal("opening_beat"):
		PeopleDirection.connect("opening_beat",_on_beat)
	terrain._set_game_speed(5)
	var total_days:=int(years*365.0)
	var settled_try:=0
	var chunk_ms:=0
	var last_year_mark:=-1
	while GameState.elapsed_days<total_days:
		if not GameState.settlement_site_committed:
			# A plausible player settles once the convoy has had a few days.
			if int(GameState.elapsed_days)>=settled_try:
				settled_try=int(GameState.elapsed_days)+3
				terrain._start_settlement_here()
				if GameState.settlement_site_committed:
					w("settled",{"status":String(terrain.travel_status_label.text) if terrain.travel_status_label else ""})
					founded_day=int(GameState.elapsed_days)
					# The founding frame: what opens by itself, what the rail offers.
					for i in 3:await get_tree().process_frame
					_first_ten_sample()
					w("ui",UiMeasure.measure(terrain,"founding"))
		if is_instance_valid(terrain.settlement_naming_panel):terrain.settlement_naming_panel.queue_free()
		if PeopleDirection.needs_century_choice():
			w("century_choice",{});PeopleDirection.choose(ambition)
			if is_instance_valid(PeopleDirection.panel):PeopleDirection.panel.queue_free()
		if terrain.game_speed<=0.0:
			var dlg=terrain.military_attention_dialog
			w("paused",{"title":String(dlg.title) if dlg and is_instance_valid(dlg) else "","body":String(dlg.dialog_text).left(400) if dlg and is_instance_valid(dlg) else ""})
			if dlg and is_instance_valid(dlg):dlg.queue_free()
			terrain._set_game_speed(5)
			if terrain.game_speed<=0.0:
				# something else holds the pause
				SimulationPauseRelease.release_all(terrain)
				terrain._set_game_speed(5)
		var s:=Time.get_ticks_msec()
		terrain.advance_world_time(1.0)
		chunk_ms+=Time.get_ticks_msec()-s
		await get_tree().process_frame
		_collect()
		_handle_court()
		if founded_day>=0 and GameState.elapsed_days<=founded_day+600:_first_ten_sample()
		elif founded_day>=0 and not ui_marks.has("first_ten"):
			ui_marks["first_ten"]=true
			w("ui_first_ten",first_ten)
		_handle_aims()
		var y:=int(GameState.elapsed_days/365.0)
		if y!=last_year_mark:
			last_year_mark=y
			_year_row(y,chunk_ms);chunk_ms=0
			if y in [1,5,10,25] and not ui_marks.has(y):
				ui_marks[y]=true
				w("ui",UiMeasure.measure(terrain,"year %d" % y))
	_collect()
	w("end",{"counts":counts,"inbox":GameState.council_inbox.size(),"matters":Hall.matter_counts(),"hall_history":(Hall.state().get("history",[]) as Array).size()})
	out.close()
	print("FUN_PLAYTEST DONE ",counts)
	get_tree().quit(0)

## The first ten real minutes (600 game days at 1 day/s) after founding: the
## largest surface of rail entries, top-strip chips and self-opened dock tiles.
func _first_ten_sample()->void:
	var hud:Node=terrain.hud
	var rail:=UiMeasure.rail_visible(hud).size()
	var kpis:=UiMeasure.kpi_visible(hud).size()
	var tiles:=0
	if hud.dock.visible and String(hud.active_section)!="":
		tiles=UiMeasure.provider_items(hud,String(hud.active_section),int(hud.dock.sub))
		var tag:="%s@%d" % [String(hud.active_section),int(GameState.elapsed_days)-founded_day]
		if (first_ten.auto_docks as Array).size()<8 and not (first_ten.auto_docks as Array).any(func(x:String)->bool:return x.begins_with(String(hud.active_section)+"@")):(first_ten.auto_docks as Array).append(tag)
	first_ten.rail_max=maxi(int(first_ten.rail_max),rail)
	first_ten.kpi_max=maxi(int(first_ten.kpi_max),kpis)
	first_ten.dock_tiles_max=maxi(int(first_ten.dock_tiles_max),tiles)
	first_ten.max_surface=maxi(int(first_ten.max_surface),rail+kpis+tiles)

func _on_beat(beat:Dictionary)->void:
	w("beat",{"kind":String(beat.get("kind","")),"title":String(beat.get("title","")),"text":String(beat.get("text","")).left(400)})

func _year_row(y:int,ms:int)->void:
	var civ_contacts:=0
	for c in CivilizationSystem.civilizations:
		if int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))>0:civ_contacts+=1
	w("year",{"year":y,"ms_last_year":ms,"pop":GameState.population_total,"known":GameState.known_discoveries.size(),"food_days":GameState.simulation_metrics.get("food_days",0),"intake":GameState.simulation_metrics.get("food_intake_ratio",0),"built":GameState.settlement_completed.size(),"settlements":GameState.player_settlements.size(),"contacts":civ_contacts,"civs":CivilizationSystem.civilizations.size(),"scout_reports":CivilizationSystem.scout_reports.size(),"officials":GovernmentPeopleSystem.active_offices().size() if GovernmentPeopleSystem.has_method("active_offices") else -1,"matters":Hall.matter_counts(),"chronicle":(CivilizationSystem.chronicle.data.get("chapters",[]) as Array).size() if CivilizationSystem.chronicle else -1,"stage":String(GameState.get("settlement_stage")) if "settlement_stage" in GameState else "","aim":_aim_row()})

func _aim_row()->Dictionary:
	if aims==null: return {}
	var model:Dictionary=aims.call("board_model")
	var live:Dictionary=model.get("active",{})
	return {"title":String(live.get("title","")),"progress":float(live.get("progress",0.0)),"words":String(live.get("words","")),"left":int(live.get("years_left",0)),"stats":(aims.call("state") as Dictionary).get("stats",{}),"legacies":(model.get("legacies",[]) as Array).size(),"rivals":(model.get("rivals",[]) as Array).map(func(r:Dictionary)->String:return String(r.civ_name)+": "+String(r.title))}

func _handle_aims()->void:
	## A plausible player summons whoever holds an aim matter within a few
	## weeks to a season, and answers. "--aims=silent" never summons.
	if aims==null: return
	var log_list:Array=(aims.call("state") as Dictionary).get("log",[])
	for i in range(log_list.size()-1,-1,-1):
		var entry:Dictionary=log_list[i]
		var key:="%d|%s|%s" % [int(entry.get("day",0)),String(entry.get("kind","")),String(entry.get("text",""))]
		if aim_logged.has(key): continue
		aim_logged[key]=true
		var row:=entry.duplicate(); row.erase("day")
		row["aim_kind"]=String(row.get("kind","")); row.erase("kind")
		w("aim",row)
	if aim_policy=="silent": return
	for m in Hall.matters():
		if String(m.get("situation_type",""))!="aim": continue
		var id:=String(m.get("id",""))
		if not aim_due.has(id): aim_due[id]=int(GameState.elapsed_days)+rng.randi_range(15,75)
		if int(GameState.elapsed_days)<int(aim_due[id]): continue
		var opened:Dictionary=Hall.open_matter(id)
		if opened.is_empty(): continue
		var aid:=String(opened.get("id",""))
		handled_audiences[aid]=true
		var opts:=Hall.options(aid)
		var ids:Array=opts.map(func(o:Dictionary)->String:return String(o.id))
		var adopts:Array=ids.filter(func(x:String)->bool:return x.begins_with("aim_adopt:"))
		var pick:=""
		var roll:=rng.randf()
		if not adopts.is_empty():
			if "aim_keep" in ids: pick=String(adopts[0]) if roll<0.5 else "aim_keep"
			elif roll<0.85: pick=String(adopts[0]) if rng.randf()<0.5 else String(adopts[rng.randi()%adopts.size()])
			else: pick="aim_wait"
		else:
			var course:=["aim_press","aim_extend","aim_hold","aim_press","aim_extend","aim_release"]
			pick=String(course[rng.randi()%course.size()])
			if not pick in ids: pick=String(ids[0])
		var lines:Array=(Hall.find(aid).get("lines",[]) as Array).map(func(l:Dictionary)->String:return ("%s: " % String(l.get("speaker","")) if String(l.get("speaker",""))!="" else "")+String(l.get("text","")))
		var r:=Hall.resolve(aid,pick)
		w("aim_decision",{"holder":String((m.get("holder",{}) as Dictionary).get("name","")),"summary":String(m.get("summary","")).left(300),"options":opts.map(func(o:Dictionary)->String:return String(o.label)),"pick":pick,"lines":lines,"outcome":String(r.get("outcome",r.get("error",""))).left(300)})

func _collect()->void:
	for e in GameState.simulation_events:
		var k:="%s|%s|%s"%[e.get("day",""),e.get("title",""),String(e.get("description","")).left(40)]
		if seen_events.has(k):continue
		seen_events[k]=true
		w("event",{"title":String(e.get("title","")),"desc":String(e.get("description","")),"sev":String(e.get("severity","")),"domain":String(e.get("domain",""))})
	for item in GameState.council_inbox:
		var k:=str(item.get("id",JSON.stringify(item).md5_text()))
		if seen_inbox.has(k):continue
		seen_inbox[k]=true
		w("council",{"title":String(item.get("advisor",""))+" / "+String(item.get("office",""))+" / "+String(item.get("topic","")),"body":String(item.get("text","")).left(300),"kind":String(item.get("condition_key",""))})
	for m in Hall.state().get("matters",[]):
		if not m is Dictionary or seen_matters.has(String(m.get("id",""))+str(m.get("day",""))):continue
		seen_matters[String(m.get("id",""))+str(m.get("day",""))]=true
		w("matter",{"holder":String((m.get("holder",{}) as Dictionary).get("title",""))+" "+String((m.get("holder",{}) as Dictionary).get("name","")),"kind":String(m.get("kind","")),"situation":String(m.get("situation_type","")),"summary":String(m.get("summary","")).left(300),"urgency":float(m.get("urgency",0))})
	for id in GameState.known_discoveries:
		if known_logged.has(String(id)):continue
		known_logged[String(id)]=true
		if GameState.elapsed_days>1:w("discovery",{"id":String(id),"name":String(DiscoverySystem.player_facing_discovery_event({"id":String(id)}).get("name",id))})
	for d in quiet.log:w("discovery_popup",d)
	quiet.log.clear()
	if terrain.travel_status_label and terrain.travel_status_label.text!=last_status:
		last_status=terrain.travel_status_label.text
		w("ticker",{"text":last_status.left(300)})
	# The Chronicle feed (scripts/chronicle.gd), when this build has one.
	var feed:Array=(GameState.get("chronicle") as Dictionary).get("entries",[]) if GameState.get("chronicle") is Dictionary else []
	for i in range(feed.size()-1,-1,-1):
		var entry:Dictionary=feed[i]
		var fk:=String(entry.get("key",""))
		if seen_feed.has(fk):continue
		seen_feed[fk]=true
		w("feed",{"tier":String(entry.get("tier","")),"kind":String(entry.get("kind","")),"title":String(entry.get("title","")),"text":String(entry.get("text","")).left(300),"entry_day":int(entry.get("day",0))})
	if CivilizationSystem.chronicle:
		for ch in CivilizationSystem.chronicle.data.get("chapters",[]):
			var k:=JSON.stringify(ch).md5_text()
			if seen_chron.has(k):continue
			seen_chron[k]=true
			w("chronicle",{"text":JSON.stringify(ch).left(400)})

func _handle_court()->void:
	var dir:Node=get_tree().get_first_node_in_group("court_director")
	if dir==null:return
	for i in 4:
		await get_tree().process_frame
		if is_instance_valid(dir.modal):break
	if not is_instance_valid(dir.modal):
		# badge waiting but never auto-opened?
		if not Hall.waiting().is_empty():w("waiting_unopened",{"n":Hall.waiting().size()})
		return
	var id:String=String(dir.modal.audience_id)
	if handled_audiences.has(id):return
	handled_audiences[id]=true
	var a:=Hall.find(id)
	var opts:=Hall.options(id)
	var enabled:Array=[]
	for o in opts:
		if bool(o.get("enabled",true)):enabled.append(o)
	var pick:Dictionary=_pick(a,enabled)
	var situation:Dictionary=a.get("situation",{}) if a.get("situation") is Dictionary else {}
	var spoken:Array=[]
	for line in a.get("lines",[]):
		if line is Dictionary:spoken.append("%s: %s" % [String(line.get("speaker","")),String(line.get("text",""))])
	w("audience",{"kind":String(a.get("kind","")),"situation":String(situation.get("type","")),"speaker":str((a.get("speaker",{}) as Dictionary).get("name","")) if a.get("speaker") is Dictionary else "","origin":String(a.get("origin","")),"civ":String(a.get("civ_id","")),"title":String(a.get("title",a.get("headline",""))),"facts":String(situation.get("summary","")).left(600),
		"string":String((situation.get("string",{}) as Dictionary).get("type","")) if situation.get("string") is Dictionary else "","recall":situation.get("recall",{}) if situation.get("recall") is Dictionary else {},"ruler":String(situation.get("ruler","")),"tells":situation.get("tells",[]) if situation.get("tells") is Array else [],
		"lines":spoken,"options":opts.map(func(o):return String(o.get("id",""))+":"+String(o.get("label",""))+" — "+String(o.get("sub",""))+(" | "+String(o.get("objection","")) if String(o.get("objection",""))!="" else "")),"pick":String(pick.get("id","")),"policy":policy})
	if not pick.is_empty():
		var r:=Hall.resolve(id,String(pick.id))
		w("audience_result",{"outcome":String(r.get("outcome",r.get("message",""))).left(400),"pick":String(pick.get("id",""))})
	dir.modal.queue_free()
	await get_tree().process_frame
	# release any pause the modal took
	SimulationPauseRelease.release_all(terrain)
	terrain._set_game_speed(5)

func _pick(a:Dictionary,enabled:Array)->Dictionary:
	if enabled.is_empty():return {}
	if policy!="heuristic":return enabled[rng.randi()%enabled.size()]
	## A careful player: prefers warm answers, heeds a court member's objection
	## and a stated cost, and calls a threat whose tells show it is a bluff.
	var situation:Dictionary=a.get("situation",{}) if a.get("situation") is Dictionary else {}
	var tells:Array=situation.get("tells",[]) if situation.get("tells") is Array else []
	if not (situation.get("signs",[]) as Array).is_empty():tells=[]
	var best:Dictionary={};var best_score:=-INF
	for o in enabled:
		var score:float={"warm":0.6,"neutral":0.3,"hostile":-0.4}.get(String(o.get("tone","neutral")),0.0)
		var cost_text:=String(o.get("cost",""))
		if cost_text!="":score-=0.7 if cost_text.begins_with("String") else 0.3
		if String(o.get("objection",""))!="":score-=1.0
		if String(o.get("support",""))!="":score+=0.9
		var oid:=String(o.get("id",""))
		if not tells.is_empty() and oid in ["defy","counter"]:score+=2.0
		if not tells.is_empty() and oid=="pay":score-=1.0
		score+=rng.randf()*0.3
		if score>best_score:best_score=score;best=o
	return best

class SimulationPauseRelease:
	static func release_all(t:Node)->void:
		var P:=preload("res://scripts/hud/simulation_pause.gd")
		P.owners.erase(t.get_instance_id())
