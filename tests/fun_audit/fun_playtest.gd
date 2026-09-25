extends Node
## FUN AUDIT harness (uncommitted, read-only audit). Runs the real game scene
## through the same advance_world_time/_commit_world_day path, answers envoys
## like a plausible player, and logs everything the player would be told.
## Requires the worktree override.cfg (isolated userdata). Never saves.
##   <godot> --headless --path <worktree> res://tests/fun_audit/fun_playtest.tscn -- --years=30 --seed=424242 --out=<file>
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
var last_status:=""
var rng:=RandomNumberGenerator.new()
var counts:Dictionary={}

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n):return a.substr(n.length()+3)
	return f

func w(kind:String,data:Dictionary)->void:
	data["t"]=kind;data["day"]=int(GameState.elapsed_days)
	out.store_line(JSON.stringify(data))
	counts[kind]=int(counts.get(kind,0))+1

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowFunAuditTests"):
		push_error("needs isolated userdata");get_tree().quit(2);return
	var years:=float(_arg("years","30"))
	var seed_value:=int(_arg("seed","424242"))
	var ambition:=_arg("ambition","makers")
	rng.seed=seed_value
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
				if GameState.settlement_site_committed:w("settled",{"status":String(terrain.travel_status_label.text) if terrain.travel_status_label else ""})
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
		var y:=int(GameState.elapsed_days/365.0)
		if y!=last_year_mark:
			last_year_mark=y
			_year_row(y,chunk_ms);chunk_ms=0
	_collect()
	w("end",{"counts":counts,"inbox":GameState.council_inbox.size(),"matters":Hall.matter_counts(),"hall_history":(Hall.state().get("history",[]) as Array).size()})
	out.close()
	print("FUN_PLAYTEST DONE ",counts)
	get_tree().quit(0)

func _year_row(y:int,ms:int)->void:
	var civ_contacts:=0
	for c in CivilizationSystem.civilizations:
		if int((c.get("player_relation",{}) as Dictionary).get("contact_level",0))>0:civ_contacts+=1
	w("year",{"year":y,"ms_last_year":ms,"pop":GameState.population_total,"known":GameState.known_discoveries.size(),"food_days":GameState.simulation_metrics.get("food_days",0),"intake":GameState.simulation_metrics.get("food_intake_ratio",0),"built":GameState.settlement_completed.size(),"settlements":GameState.player_settlements.size(),"contacts":civ_contacts,"civs":CivilizationSystem.civilizations.size(),"scout_reports":CivilizationSystem.scout_reports.size(),"officials":GovernmentPeopleSystem.active_offices().size() if GovernmentPeopleSystem.has_method("active_offices") else -1,"matters":Hall.matter_counts(),"chronicle":(CivilizationSystem.chronicle.data.get("chapters",[]) as Array).size() if CivilizationSystem.chronicle else -1,"stage":String(GameState.get("settlement_stage")) if "settlement_stage" in GameState else ""})

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
	for d in quiet.log:w("discovery_popup",d)
	quiet.log.clear()
	if terrain.travel_status_label and terrain.travel_status_label.text!=last_status:
		last_status=terrain.travel_status_label.text
		w("ticker",{"text":last_status.left(300)})
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
	var a:=Hall.find(id)
	var opts:=Hall.options(id)
	var enabled:Array=[]
	for o in opts:
		if bool(o.get("enabled",true)):enabled.append(o)
	var pick:Dictionary=enabled[rng.randi()%enabled.size()] if not enabled.is_empty() else {}
	var lines:Array=[]
	w("audience",{"kind":String(a.get("kind","")),"situation":String(a.get("situation","")),"origin":String(a.get("origin","")),"civ":String(a.get("civ_id","")),"title":String(a.get("title",a.get("headline",""))),"facts":str(a.get("facts","")).left(300),"options":opts.map(func(o):return String(o.get("id",""))+":"+String(o.get("label",""))),"pick":String(pick.get("id",""))})
	if not pick.is_empty():
		var r:=Hall.resolve(id,String(pick.id))
		w("audience_result",{"outcome":String(r.get("outcome",r.get("message",""))).left(300)})
	dir.modal.queue_free()
	await get_tree().process_frame
	# release any pause the modal took
	SimulationPauseRelease.release_all(terrain)
	terrain._set_game_speed(5)

class SimulationPauseRelease:
	static func release_all(t:Node)->void:
		var P:=preload("res://scripts/hud/simulation_pause.gd")
		P.owners.erase(t.get_instance_id())
