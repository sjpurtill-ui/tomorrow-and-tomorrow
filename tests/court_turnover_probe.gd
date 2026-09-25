extends Node
## Round-3 court fixes (fun audit 2, items 4, 7 and 8), offline and headless:
## - names: children are named for their sex in the people's tradition, and
##   no generated person or hearth carries a real-world name;
## - officials who are already grown live adult spans (about 50-65);
## - repaying a debt is not yielding to a rival's vow, paying tribute is;
## - the five miracle orders each do something different (their rites);
## - "Build a great temple to me on the hill" commissions a great work;
## - order replies do not lean on one frame.
##   <godot> --headless --path <worktree> res://tests/court_turnover_probe.tscn

const Universal:=preload("res://tests/universal_order_probe.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const Aims:=preload("res://scripts/legacy_aims.gd")
const CustomDirective:=preload("res://scripts/custom_directive.gd")
const MIRACLES:=["Make it rain tomorrow.","Raise the dead from the burial mound.","Teach the people to fly.","Turn the river stones into gold.","Stop the winter from coming."]
## Real-world names the old pools used; none may come back.
const REAL:=["Soraya","Farid","Laleh","Hana","Nadiya","Dimitra","Yejun","Qureshi","Chandra","Yi","Eleanor","William","Alasdair","Zhao","Mehrani"]

var failures:Array[String]=[]

func _expect(ok:bool,message:String)->void:
	if not ok: failures.append(message)

func _ready()->void:
	var probe:Node=Universal.new()
	probe._world()
	# Names --------------------------------------------------------------
	var wrong_sex:=0; var real:=0
	for i in 200:
		var daughter:=i%2==0
		var given:=EraNames.given_for(int(GameState.world_seed),"probe:%d" % i,daughter,"player",{})
		if not EraNames.is_given_of_sex(given,daughter): wrong_sex+=1
		if given in REAL: real+=1
		var hearth:Dictionary=EraNames.hearth_of(int(GameState.world_seed),"probe:%d" % i,"player")
		for word in String(hearth.name).split(" "):
			if word.trim_suffix("'s") in REAL: real+=1
	for tradition in HistoricalNameGenerator.POOLS:
		var made:=HistoricalNameGenerator.make(7,3,true,String(tradition),{})
		for word in String(made.name).split(" "):
			if word in REAL: real+=1
	for word in GovernmentPeopleSystem.GIVEN_NAMES+GovernmentPeopleSystem.FAMILY_NAMES:
		if String(word) in REAL: real+=1
	print("METRIC names wrong_sex=%d real=%d" % [wrong_sex,real])
	_expect(wrong_sex==0,"%d children named for the other sex" % wrong_sex)
	_expect(real==0,"%d real-world names generated" % real)
	# Adult lifespans ----------------------------------------------------
	var rng:=RandomNumberGenerator.new(); rng.seed=5
	var total:=0.0; var n:=0; var under_45:=0
	for age in [20,25,30,35,40,45,50]:
		for k in 200:
			var death:=GovernmentPeopleSystem.adult_death_age(rng,age,22.0)
			total+=death; n+=1
			if death<45.0: under_45+=1
	var mean:=total/float(n)
	print("METRIC adult_death_age mean=%.1f under_45=%.1f%%" % [mean,100.0*float(under_45)/float(n)])
	_expect(mean>=52.0 and mean<=66.0,"adult death age mean %.1f outside 52-66" % mean)
	_expect(float(under_45)/float(n)<0.15,"too many adults die before 45")
	# Yielding -----------------------------------------------------------
	_expect(not Aims.is_yield("request","debt_call","grant"),"repaying a debt counts as yielding")
	_expect(not Aims.is_yield("request","aid_request","grant"),"feeding the hungry counts as yielding")
	_expect(Aims.is_yield("threat","tribute_demand","pay"),"paying tribute does not count as yielding")
	# Contradictions and rival warnings ----------------------------------------
	var world:Node=preload("res://tests/audience_modal_probe.gd").new()
	world._setup_world()
	world.free()
	PeopleDirection.reset_for_new_world(); PeopleDirection.ensure()
	var civ:Dictionary={}
	for c in CivilizationSystem.civilizations:
		if c is Dictionary: civ=c; break
	if not civ.is_empty():
		var civ_id:=String(civ.id)
		(civ.player_relation as Dictionary)["treaty"]="exchange"
		var clash:=Aims.contradiction({"template":"fear","subject":civ_id,"subject_name":String(civ.name)})
		print("CONTRADICTION | %s" % clash)
		_expect(clash!="","a fear aim against a people we keep a pact with is not flagged")
		(civ.player_relation as Dictionary)["treaty"]=""
		var r:Dictionary={"civ_id":civ_id,"civ_name":String(civ.name),"template":"humble","title":"Make the God's People Yield","phrase":"make us yield to them","start_day":0,"deadline":99999,"years":10,"status":"active","known":false,"progress":0.5,"leader":"Oskel","target":2.0,"baseline":0.0}
		(Aims.state().rivals as Dictionary)[civ_id]=r
		Aims._rival_warn(r,int(GameState.elapsed_days))
		var warned:=false
		for entry in Aims.state().log:
			if String((entry as Dictionary).get("kind",""))=="rival_warned": warned=true
		_expect(warned and bool(r.known),"a rival vow near completion was not told")
		var options:Array[Dictionary]=[{"id":"grant","sub":"Give it."}]
		Aims.annotate_options({"civ_id":civ_id,"kind":"request","situation":{"type":"debt_call"}},options)
		var tribute:Array[Dictionary]=[{"id":"pay","sub":"Pay it."}]
		Aims.annotate_options({"civ_id":civ_id,"kind":"threat","situation":{"type":"tribute_demand"}},tribute)
		options.append(tribute[0])
		print("ANNOTATED | %s | %s" % [String(options[0].sub),String(options[1].sub)])
		_expect(String(options[0].sub).contains("not yielding"),"repaying a debt is not marked as not yielding")
		_expect(String(options[1].sub).contains("yielding ("),"paying tribute is not marked as yielding")
	else:
		failures.append("no neighbour in the probe world")
	# Miracles -----------------------------------------------------------
	var sets:Dictionary={}
	for text in MIRACLES:
		var plan:=CustomDirective.offline_plan(text)
		var signature:Array[String]=[]
		for effect in plan.get("effects",[]): signature.append("%s%s" % [String(effect.parameter),"+" if float(effect.strength)>0.0 else "-"])
		signature.sort()
		sets[",".join(signature)]=text
		print("MIRACLE | %s | %s | %d days | %s" % [text,String(plan.get("rite_kind","")),int(plan.get("days",0)),",".join(signature)])
	print("METRIC miracle_effect_sets=%d/%d" % [sets.size(),MIRACLES.size()])
	_expect(sets.size()==MIRACLES.size(),"miracles share effect sets (%d distinct of %d)" % [sets.size(),MIRACLES.size()])
	# Great work from an order ----------------------------------------------
	var city:String=probe._world()
	var leader:=GovernmentPeopleSystem.settlement_leader(city)
	var text:="Build a great temple to me on the hill."
	var order:=AdvisorSystem.begin_civic_directive(text,city,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(text,PronouncementInterpreter._local_interpretation(text,{"settlement":{"id":city}}),order,city,int(leader.get("person_id",0)))
	var work:Dictionary=resolved.get("great_work",{}) if resolved.get("great_work") is Dictionary else {}
	var building:=0
	for w in preload("res://scripts/great_works.gd").works("player"):
		if String((w as Dictionary).get("status",""))=="building": building+=1
	print("GREAT WORK | %s | started=%s | building=%d | %s" % [text,str(work.get("started",false)),building,String(resolved.get("leader_reply","")).split("\n\n")[0]])
	_expect(bool(work.get("started",false)) and building==1,"a great temple order did not start a great work")
	# Reply frames -------------------------------------------------------
	var frames:Dictionary={}
	var reply_script:GDScript=load("res://scripts/divine_reply.gd")
	for order_variant in Universal.ORDERS:
		var said:=String(order_variant)
		city=probe._world()
		leader=GovernmentPeopleSystem.settlement_leader(city)
		reply_script.set("last_frame","")
		var o:=AdvisorSystem.begin_civic_directive(said,city,leader)
		AdvisorSystem.resolve_civic_directive(said,PronouncementInterpreter._local_interpretation(said,{"settlement":{"id":city}}),o,city,int(leader.get("person_id",0)))
		var frame:=String(reply_script.get("last_frame"))
		var family:=frame.get_slice(":",0) if frame!="" else "other"
		frames[family]=int(frames.get(family,0))+1
	var top:=0
	for key in frames: top=maxi(top,int(frames[key]))
	print("METRIC reply_frames=%s top_share=%.0f%%" % [JSON.stringify(frames),100.0*float(top)/float(Universal.ORDERS.size())])
	_expect(float(top)/float(Universal.ORDERS.size())<=0.45,"one reply frame family dominates")
	probe.free()
	if failures.is_empty():
		print("COURT_TURNOVER_PROBE PASS")
		get_tree().quit(0)
		return
	for failure in failures: push_error(failure)
	print("COURT_TURNOVER_PROBE FAIL (%d)" % failures.size())
	get_tree().quit(1)
