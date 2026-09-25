extends Node
## Generational aims (legacy_aims.gd), end to end and offline:
## - the court proposes 2-3 aims from real state, from at least two voices,
##   and they wait as a court matter (never an unbidden audience);
## - summoned, the court urges them in its own voices; the god takes one up;
## - progress is measured from the real simulation, milestones and the
##   outcome are told in the Chronicle; fulfilment brings love, legitimacy and
##   a named legacy; failure brings grief and dread but not ruin;
## - if the god is silent, the people take up an aim themselves;
## - a lagging aim brings its keeper back to court (press, extend, hold, let go);
## - typed aims map onto measurable, historically bounded targets;
## - rivals hold aims, learned from their envoys, and some clash with ours;
## - aims never end the game; the old visions are retired;
## - the saved state validates and older saves without aims still load.
##   <godot> --headless --path <worktree> res://tests/legacy_aims_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const CV:=preload("res://scripts/character_voice.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")

var failures:Array[String]=[]
var transcript:Array[String]=[]

func _check(ok:bool,text:String)->void:
	if not ok:
		failures.append(text); printerr("LEGACY_AIMS FAIL: ",text)

func _world()->void:
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	CV.knowledge_override.clear()
	PeopleDirection.reset_for_new_world(); PeopleDirection.ensure()
	PeopleDirection.choose("makers")
	GameState.settlement_founded_day=1
	GameState.elapsed_days=2

func _advance(to_day:int)->void:
	var start:=int(GameState.elapsed_days)
	for day in range(start+1,to_day+1):
		GameState.elapsed_days=day
		GovernmentPeopleSystem.process_day(day)
		Hall.daily(day)

func _aim_matter()->Dictionary:
	for m in Hall.matters():
		if String(m.get("situation_type",""))=="aim": return m
	return {}

func _open_aim()->Dictionary:
	var m:=_aim_matter()
	if m.is_empty(): return {}
	return Hall.open_matter(String(m.id))

func _chronicle_titles()->Array[String]:
	var out:Array[String]=[]
	for entry in Chronicle.entries("notice"): out.append(String(entry.get("title","")))
	return out

func _ready()->void:
	_world()
	_test_proposal_and_adoption()
	_test_fulfilment()
	_test_failure()
	_test_silence()
	_test_course()
	_test_halfway()
	_test_typed()
	_test_rivals()
	_test_rival_characters()
	_test_save_and_visions()
	_finish()

# ---------------------------------------------------------------------------

func _test_proposal_and_adoption()->void:
	_advance(Aims.FIRST_PROPOSAL_DAYS-5)
	_check(_aim_matter().is_empty(),"no aim is proposed before the court has settled")
	_advance(Aims.FIRST_PROPOSAL_DAYS+15)
	var m:=_aim_matter()
	_check(not m.is_empty(),"the court holds an aim proposal as a matter")
	_check(Hall.waiting().is_empty(),"an aim never arrives unbidden")
	var opened:=_open_aim()
	_check(not opened.is_empty(),"the proposal can be taken up")
	var id:=String(opened.get("id",""))
	var lines:Array=Hall.find(id).get("lines",[])
	var speakers:Dictionary={}
	for line in lines:
		transcript.append("  [%s] %s" % [String(line.get("speaker","narrator")),String(line.get("text",""))])
		speakers[String(line.get("speaker",""))]=true
		_check(CV.permits(String(line.get("text","")),CV.era_tags("player")),"era-safe line: %s" % String(line.get("text","")))
	_check(lines.size()>=3,"the court urges its aims in several lines (%d)" % lines.size())
	_check(speakers.size()>=2,"at least two voices speak (%d)" % speakers.size())
	var opts:=Hall.options(id)
	var adopts:=opts.filter(func(o:Dictionary)->bool:return String(o.id).begins_with("aim_adopt:"))
	_check(adopts.size()>=2 and adopts.size()<=3,"two or three aims are offered (%d)" % adopts.size())
	_check(opts.any(func(o:Dictionary)->bool:return String(o.id)=="aim_wait"),"the god may bid them wait")
	for o in opts: transcript.append("  OPTION %s — %s" % [String(o.label),String(o.sub)])
	var before:=int(PeopleDirection.cultural_memory.events.size())
	# Choose the stone ring if offered, else the first.
	var pick:=String(adopts[0].id)
	for o in adopts:
		if String(o.label).contains("Stones") or String(o.label).contains("Hearths Hold"): pick=String(o.id)
	var r:=Hall.resolve(id,pick)
	transcript.append("  OUTCOME %s" % String(r.get("outcome","")))
	_check(bool(r.get("ok",false)),"taking up an aim resolves")
	_check(Aims.has_active(),"an aim is live")
	var aim:=Aims.active()
	var years:=int(aim.get("years",0))
	_check(years>=Aims.MIN_YEARS and years<=Aims.MAX_YEARS,"aim lasts 5-25 years (%d)" % years)
	_check(int(PeopleDirection.cultural_memory.events.size())>before,"taking up an aim records a cultural action for its ambition")
	_check("An Aim for a Generation: %s" % String(aim.title) in _chronicle_titles(),"the Chronicle tells the aim taken up")
	_check(Aims.board_model().active.get("title","")==String(aim.title),"the board shows the live aim")
	_check(Aims.court_line().begins_with("The people strive"),"the court roll shows the live aim")
	var board:VBoxContainer=preload("res://scripts/hud/known_world_board.gd").new()
	add_child(board)
	board.setup({"model":{"aims":Aims.board_model()}})
	var title:=board.find_child("AimTitle",true,false) as Label
	_check(board.find_child("AimsSheet",true,false)!=null and title!=null and title.text==String(aim.title),"the Known World shows the live aim")
	_check(board.find_child("AimProgress",true,false)!=null,"the Known World shows the aim's progress")
	board.queue_free()

func _test_fulfilment()->void:
	var aim:=Aims.active()
	var legit:=float(GameState.simulation_metrics.get("legitimacy",0.5))
	# Make the world agree with the aim: its measure reaches the target.
	match String(aim.template):
		"grow": GameState.ensure_population_total(int(aim.target)+2)
		"plenty","work": aim.acc=float(aim.target)
		"knowledge":
			for i in int(aim.target)+1: GameState.known_discoveries.append("probe_way_%d" % i)
		"settle": GameState.player_settlements.append({"id":"probe_daughter","name":"Probe"})
		"learn": aim.baseline=Aims.known_in(String(aim.subject))-int(aim.target)
		"unity": GameState.simulation_metrics["cohesion"]=float(aim.target)+0.01
		_: aim.progress=1.0
	var day:=int(GameState.elapsed_days)
	_advance(day+60)
	_check(not Aims.has_active() or String(Aims.active().id)!=String(aim.id),"the aim was fulfilled")
	var legacies:Array=Aims.state().legacies
	_check(not legacies.is_empty(),"a named legacy is remembered")
	if not legacies.is_empty(): transcript.append("LEGACY %s — %s" % [String(legacies[0].name),String(legacies[0].text)])
	_check(float(GameState.simulation_metrics.get("legitimacy",0.5))>legit,"fulfilment raises legitimacy")
	var told:=false
	for t in _chronicle_titles(): told=told or t.begins_with("Remembered:")
	_check(told,"the Chronicle remembers the legacy")
	# Aims never end the game: another is proposed after a rest.
	_advance(int(GameState.elapsed_days)+Aims.REST_MAX+20)
	_check(not _aim_matter().is_empty(),"a new aim is proposed after the old one is done")

func _test_failure()->void:
	var opened:=_open_aim()
	var opts:=Hall.options(String(opened.get("id","")))
	var adopt:=""
	for o in opts:
		if String(o.id).begins_with("aim_adopt:"): adopt=String(o.id); break
	Hall.resolve(String(opened.get("id","")),adopt)
	var aim:=Aims.active()
	_check(not aim.is_empty(),"a second aim is taken up")
	var cohesion:=float(GameState.simulation_metrics.get("cohesion",0.5))
	var pop:=GameState.population_total
	aim.deadline=int(GameState.elapsed_days)+2
	aim["course_filed"]=int(GameState.elapsed_days)
	_advance(int(GameState.elapsed_days)+4)
	var last:Dictionary=Aims.state().history[0] if not (Aims.state().history as Array).is_empty() else {}
	_check(String(last.get("status",""))=="failed" or String(last.get("status",""))=="fulfilled","the aim ended at its deadline (%s)" % String(last.get("status","")))
	if String(last.get("status",""))=="failed":
		_check(float(GameState.simulation_metrics.get("cohesion",0.5))<cohesion,"failure brings grief (cohesion falls)")
		_check(float(GameState.simulation_metrics.get("cohesion",0.5))>cohesion-0.05,"failure is not ruin")
		_check(absi(GameState.population_total-pop)<=3,"failure kills no one")
		var told:=false
		for t in _chronicle_titles(): told=told or t.begins_with("An Aim Unmet")
		_check(told,"the Chronicle tells the failure")

func _test_silence()->void:
	_advance(int(GameState.elapsed_days)+Aims.REST_MAX+20)
	var m:=_aim_matter()
	_check(not m.is_empty(),"a proposal waits after the failure")
	# The god never summons them: the matter lapses and the people choose.
	_advance(int(GameState.elapsed_days)+Hall.MATTER_DAYS+5)
	_check(Aims.has_active(),"the people took up an aim when the god was silent")
	_check(String(Aims.active().get("chosen_by",""))=="people","it is marked as the people's choice")

func _test_course()->void:
	var aim:=Aims.active()
	var span:=int(aim.deadline)-int(aim.start_day)
	# Halfway through its winters with nothing to show: the keeper returns.
	aim.start_day=int(GameState.elapsed_days)-int(span*0.6)
	aim.deadline=int(aim.start_day)+span
	aim.baseline=float(aim.get("baseline",0.0))
	match String(aim.template):
		"grow": aim.target=GameState.population_total+400
		"plenty","work": aim.acc=0.0
		"knowledge": aim.target=500
		"settle": aim.target=40
		"unity": aim.target=0.99
	_advance(int(GameState.elapsed_days)+2)
	var m:=_aim_matter()
	_check(not m.is_empty() and String((m.get("audience",{}).get("situation",{}) as Dictionary).get("aim",{}).get("mode",""))=="course","a lagging aim brings its keeper back (%s)" % String(Aims.active().get("template","")))
	if m.is_empty(): return
	var opened:=Hall.open_matter(String(m.id))
	var ids:=Hall.options(String(opened.id)).map(func(o:Dictionary)->String:return String(o.id))
	_check("aim_press" in ids and "aim_extend" in ids and "aim_hold" in ids and "aim_release" in ids,"press, extend, hold and let go are offered (%s)" % str(ids))
	for line in Hall.find(String(opened.id)).get("lines",[]): transcript.append("  COURSE [%s] %s" % [String(line.get("speaker","")),String(line.get("text",""))])
	_check(Aims.typed_choice(String(opened.id),"Give them more time.",false)=="aim_extend","typed words answer the course question")
	var before:=int(Aims.active().deadline)
	var r:=Hall.resolve(String(opened.id),"aim_extend")
	_check(bool(r.get("ok",false)) and int(Aims.active().deadline)==before+730,"extending grants two more winters")

func _test_halfway()->void:
	# Halfway: the keeper asks how to mark it (a feast, a stone, or no rest).
	var entry:=Aims.file_halfway(int(GameState.elapsed_days))
	_check(not entry.is_empty(),"halfway brings the keeper back to court")
	if entry.is_empty(): return
	var opened:=Hall.open_matter(String(entry.id))
	var ids:=Hall.options(String(opened.id)).map(func(o:Dictionary)->String:return String(o.id))
	_check("aim_feast" in ids and "aim_mark" in ids and "aim_onward" in ids,"a feast, a stone or no rest (%s)" % str(ids))
	_check(Aims.typed_choice(String(opened.id),"Raise a stone to mark it",false)=="aim_mark","typed words choose the marker stone")
	for line in Hall.find(String(opened.id)).get("lines",[]): transcript.append("  HALFWAY [%s] %s" % [String(line.get("speaker","")),String(line.get("text",""))])
	var food:=float(Hall.player_stock("Food"))
	var r:=Hall.resolve(String(opened.id),"aim_feast")
	transcript.append("  HALFWAY OUTCOME %s" % String(r.get("outcome","")))
	_check(bool(r.get("ok",false)) and float(Hall.player_stock("Food"))<food,"the feast is paid from the real stores")
	_check(not preload("res://scripts/court_lives.gd").active_rites().is_empty(),"the feast burns on the map as a rite")

func _test_typed()->void:
	var pop:=GameState.population_total
	var grow:=Aims.from_words("Let us be 100000 souls.")
	_check(String(grow.get("template",""))=="grow","typed numbers map to growth")
	var band:=Aims.growth_band(GameState.elapsed_days/365.0)
	var ceiling:=float(pop)*pow(1.0+float(band.max)/100.0,float(grow.get("years",25)))
	_check(float(grow.get("target",0))<=ceiling+1.0,"a typed target stays within the era's plausible growth (%s <= %d)" % [str(grow.get("target")),int(ceiling)])
	_check(int(grow.get("years",0))<=Aims.MAX_YEARS,"a typed aim never runs past 25 years")
	var fear:=Aims.from_words("Make Varrow tremble at our name")
	_check(String(fear.get("template",""))=="fear" and String(fear.get("subject",""))=="rival_b","typed dread names the rival people (%s %s)" % [String(fear.get("template","")),String(fear.get("subject",""))])
	var odd:=Aims.from_words("Teach every child the songs of the old ones")
	_check(not odd.is_empty() and String(odd.get("title",""))!="","any typed aim is accepted")
	for words in ["Raise a great mound over the river","No child shall go hungry","Find what lies beyond the mountains","Let us learn the ways of the sky"]:
		var c:=Aims.from_words(words)
		transcript.append("TYPED %s -> %s (%s, %d winters, target %s)" % [words,String(c.get("template","")),String(c.get("title","")),int(c.get("years",0)),str(c.get("target",""))])
		_check(not c.is_empty(),"typed aim mapped: %s" % words)

func _test_rivals()->void:
	var day:=int(GameState.elapsed_days)
	var next30:=day+30-day%30
	_advance(next30+1)
	var rivals:Dictionary=Aims.state().rivals
	_check(rivals.size()>=3,"contacted peoples hold aims of their own (%d)" % rivals.size())
	# An envoy from Varrow comes: their vow is learned.
	var entry:={"day":int(GameState.elapsed_days),"audience_id":"probe_envoy","speaker":"civ:rival_b","civ_id":"rival_b","person_id":0,"kind":"threat","situation":"tribute_demand","ask":"tribute:Food","option":"pay","reaction":"","outcome":"","summary":"probe"}
	(Hall.state().ledger as Array).push_back(entry)
	_advance(int(GameState.elapsed_days)+31)
	var known:=Aims.rival_aim("rival_b")
	_check(not known.is_empty(),"a rival's aim is learned when their envoy comes")
	if not known.is_empty(): transcript.append("RIVAL %s of the %s: %s" % [String(known.leader),String(known.civ_name),String(known.phrase)])
	var told:=false
	for t in _chronicle_titles(): told=told or t.begins_with("What ")
	_check(told,"the Chronicle tells what the rival has sworn")
	_check(not Aims.board_model().rivals.is_empty(),"the board shows known rival aims")

func _test_rival_characters()->void:
	## Vows follow the ruler as a character (rival_rulers.gd rival_character):
	## an unforgotten wrong swears us humbled, and a vow passes to an heir.
	const RIVALS_PATH:="res://scripts/rival_rulers.gd"
	if not ResourceLoader.exists(RIVALS_PATH): return
	var Rivals:=load(RIVALS_PATH) as GDScript
	var rivals:Dictionary=Aims.state().rivals
	# The heir of Varrow's ruler takes up the vow.
	var vow:Dictionary=rivals.get("rival_b",{})
	if not vow.is_empty() and String(vow.get("status",""))=="active":
		var before:=String(vow.leader)
		Rivals.call("_succeed","rival_b",int(GameState.elapsed_days))
		var heir:=String((Rivals.call("rival_character","rival_b") as Dictionary).get("name",""))
		_advance(int(GameState.elapsed_days)+31)
		vow=rivals.get("rival_b",{})
		_check(String(vow.get("leader",""))==heir and heir!=before,"the heir takes up the vow (%s -> %s, heir %s)" % [before,String(vow.get("leader","")),heir])
		_check(int(vow.get("heirs",0))==1,"the vow records that it passed to an heir")
		var kept:=false
		for t in _chronicle_titles(): kept=kept or t.ends_with("Keeps the Vow")
		_check(kept,"the Chronicle tells that the heir keeps the vow")
		if kept: transcript.append("HEIR %s keeps the vow: %s" % [heir,String(vow.phrase)])
	# A ruler who has not forgotten a wrong swears to make us yield.
	var other:=""
	for civ_id in rivals:
		if String(civ_id)!="rival_b": other=String(civ_id); break
	if other=="": _check(false,"a second rival people to test a grudge"); return
	Rivals.call("grudge",other,"how you refused our gift and shamed our envoy",0.9,"probe")
	var r:Dictionary=rivals[other]
	r.status="failed"; r.rest_until=0
	var day:=int(GameState.elapsed_days)
	_advance(day+30-day%30+1)
	r=rivals[other]
	_check(String(r.get("template",""))=="humble","a grudge-bearing ruler swears to make us yield (%s)" % String(r.get("template","")))
	_check(String(r.get("why","")).contains("not forgotten"),"the vow carries the ruler's own grievance (%s)" % String(r.get("why","")))
	_check(String(r.get("trait",""))==String((Rivals.call("rival_character",other) as Dictionary).get("trait","")) and String(r.get("trait",""))!="","the vow records the ruler's trait")
	if not String(r.get("why","")).is_empty(): transcript.append("GRUDGE %s: %s %s" % [String(r.leader),String(r.phrase),String(r.why)])

func _test_save_and_visions()->void:
	var save:=PeopleDirection.export_state()
	var parsed:Dictionary=JSON.parse_string(JSON.stringify(save))
	_check(Aims.valid_state(parsed.get("aims",{})),"the aims block validates")
	var title:=String(Aims.active().get("title",""))
	_check(bool(PeopleDirection.import_state(parsed).get("ok",false)),"the save round-trips")
	_check(String(Aims.active().get("title",""))==title,"the live aim survives a reload")
	var old:=parsed.duplicate(true); old.erase("aims")
	_check(bool(PeopleDirection.import_state(old).get("ok",false)),"an older save without aims loads")
	_check(not Aims.has_active(),"an older save simply starts without an aim")
	var bad:=parsed.duplicate(true); bad["aims"]={"active":{"template":"conquer_world","start_day":0,"deadline":1}}
	_check(PeopleDirection.import_state(bad).has("error"),"an invalid aims block is refused")
	GameState.elapsed_days=5000
	_check(PeopleDirection.decide(0).has("error"),"the old one-shot visions are retired")

func _finish()->void:
	print("LEGACY_AIMS TRANSCRIPT")
	for line in transcript: print(line)
	if failures.is_empty(): print("LEGACY_AIMS PASS: proposals as matters, voiced court, adoption, measured progress, legacy, grief not ruin, silent god, course matter, typed aims, rival aims, save compatibility, visions retired")
	else:
		for f in failures: push_error(f)
	get_tree().quit(0 if failures.is_empty() else 1)
