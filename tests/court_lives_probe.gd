extends Node
## Lives at court (court_lives.gd), end to end and offline:
## - stone-age names are one name and an epithet; family names come with
##   writing; no two living court members share a given name;
## - every living court member has a picture of their own;
## - an officeholder's death becomes a mourning matter within 30 days, with at
##   least two voiced candidates; the court mourns in its own voices; the god
##   chooses (by option or by typed words) and GovernmentPeopleSystem appoints;
##   the dead join the Remembered roll; the chronicle hook hears it all;
## - every order leaves a rite on the map and a callback 30-180 days later;
## - an omen fires only when the real weather agrees, and swings love and dread;
## - rivals who dread the god send tribute, keep away, or test it;
## - the saved state validates, and older saves without it still load.
##   <godot> --headless --path <worktree> res://tests/court_lives_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const Portrait:=preload("res://scripts/hud/person_portrait.gd")
const CV:=preload("res://scripts/character_voice.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")
const Director:=preload("res://scripts/audience_director.gd")
const RiteMarks:=preload("res://scripts/rite_marks.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const ORDERS:=["Hold a feast in my honour.","Pray to me at dawn and dusk.","Carve my likeness into the cliff.","Build a palisade around the village.","Teach the children to count the stars.","Make it rain tomorrow."]

var failures:Array[String]=[]
var heard:Array[Dictionary]=[]
var transcript:Array[String]=[]

func _check(ok:bool,text:String)->void:
	if not ok:
		failures.append(text); printerr("COURT_LIVES FAIL: ",text)

func _frames(count:int)->void:
	for i in count: await get_tree().process_frame

func _world()->void:
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	CV.knowledge_override.clear()
	GameState.elapsed_days=40

func _advance(to_day:int)->void:
	## Days pass: the government's monthly lifespans, then the court's daily watch.
	var start:=int(GameState.elapsed_days)
	for day in range(start+1,to_day+1):
		GameState.elapsed_days=day
		GovernmentPeopleSystem.process_day(day)
		Hall.daily(day)

func _ready()->void:
	Lives.add_listener(_hear)
	_world()
	_test_names()
	_test_portraits()
	await _test_death_and_succession()
	_test_typed_choice()
	_test_orders_and_callbacks()
	_test_omens()
	_test_rivals()
	_test_save()
	_finish()

# ---------------------------------------------------------------------------

func _test_names()->void:
	var living:=GovernmentPeopleSystem.living_people()
	_check(living.size()>=4,"a founding cast exists (%d)" % living.size())
	var givens:Dictionary={}
	for person in living:
		var name:=String(person.get("name",""))
		transcript.append("NAME %s" % name)
		_check(String(person.get("family","x"))=="","stone-age person has no family name: %s" % name)
		_check(not givens.has(EraNames.given_of(name)),"given name repeated in court: %s" % name)
		givens[EraNames.given_of(name)]=true
		var epithet:=name.substr(EraNames.given_of(name).length()).strip_edges()
		_check(epithet!="" and CV.permits(name,[]),"stone-age name has an era-safe epithet: %s" % name)
	# Family names arrive with writing.
	CV.knowledge_override["player"]=(GameState.known_discoveries as Array)+["pictographic_records"]
	var later:=EraNames.make(int(GameState.world_seed),999,true,"player",EraNames.used_in_court())
	_check(int(later.stage)==2 and String(later.family)!="","with writing a new person has a family name: %s" % String(later.name))
	var village:=EraNames.make(int(GameState.world_seed),998,false,"player",{},{"stage":1})
	_check(String(village.name).contains(" of "),"villages name people by place: %s" % String(village.name))
	transcript.append("NAME (writing) %s · (villages) %s" % [String(later.name),String(village.name)])
	CV.knowledge_override.erase("player")
	# A foreign people sounds like itself.
	var envoy:=EraNames.make(int(GameState.world_seed),77,true,"rival_b",{})
	transcript.append("NAME (Varrow envoy) %s" % String(envoy.name))
	_check(String(envoy.family)=="","a stone-age foreign envoy has no family name either: %s" % String(envoy.name))

func _test_portraits()->void:
	Hall.daily(int(GameState.elapsed_days))
	var seen:Dictionary={}
	var faces:=Lives.court_faces()
	_check(faces.size()>=2,"the court has faces (%d)" % faces.size())
	for face in faces:
		if face.is_empty(): continue
		var pair:="%d:%s" % [Portrait.index_for(face),str(Portrait.mirrored(face))]
		_check(not seen.has(pair),"two court members share a portrait: %s and %s" % [String(seen.get(pair,"")),String(face.get("name",""))])
		seen[pair]=String(face.get("name",""))

func _office_holder(key:String)->Dictionary:
	return GovernmentPeopleSystem.officeholder(key)

func _test_death_and_succession()->void:
	var chief:=_office_holder("Steward")
	_check(not chief.is_empty(),"a Hearth Chief holds office")
	if chief.is_empty(): return
	var pid:=int(chief.person_id)
	var chief_given:=EraNames.given_of(String(chief.name))
	# Old age comes for the chief at the next monthly reckoning.
	for record in GovernmentPeopleSystem.people:
		if int(record.get("person_id",0))==pid: record["death_age_years"]=float(GovernmentPeopleSystem.age_years(record))-0.5
	var died_by:=int(GameState.elapsed_days)+30
	_advance(died_by)
	var dead:=GovernmentPeopleSystem.person_snapshot(pid)
	_check(String(dead.get("status",""))=="deceased","the chief died within 30 days")
	var mourning:Dictionary={}
	for m in Hall.matters():
		if String(m.get("situation_type",""))=="mourning": mourning=m
	_check(not mourning.is_empty(),"a mourning matter waits within 30 days of the death")
	if mourning.is_empty(): return
	var situation:Dictionary=(mourning.audience as Dictionary).situation
	var candidates:Array=(situation.mourning as Dictionary).candidates
	_check(candidates.size()>=2,"at least two successor candidates (%d)" % candidates.size())
	var roll:=Lives.remembered()
	_check(not roll.is_empty() and int(roll[0].get("pid",0))==pid,"the chief is on the Remembered roll")
	_check(heard.any(func(e:Dictionary)->bool:return String(e.kind)=="death"),"the chronicle hook heard the death")
	var events:=GameState.simulation_events.filter(func(e:Variant)->bool:return e is Dictionary and String(e.get("title",""))=="Officeholder Died" and String(e.get("description","")).begins_with(String(chief.name)))
	_check(events.is_empty(),"the HR notice was replaced by the court's words")
	# The god summons the holder: the modal opens on the mourning.
	var terrain:=ModalProbe.TerrainDouble.new(); terrain.name="TerrainDouble"; add_child(terrain)
	var director:=Director.new(); director.terrain=terrain; add_child(director)
	if "force_offline" in director.voice: director.voice.force_offline=true
	await _frames(2)
	var holder:Dictionary=mourning.holder
	var opened:=Hall.summon({"person_id":int(holder.get("person_id",0))})
	_check(String((opened.get("situation",{}) as Dictionary).get("type",""))=="mourning","summoning the holder opens the mourning first")
	var modal:Control=director.open_audience(String(opened.get("id","")))
	await _frames(6)
	if is_instance_valid(modal): modal.skip_reveal()
	await _frames(3)
	var lines:Array=(Hall.find(String(opened.id)).get("lines",[]) as Array).duplicate()
	var voiced:=0; var pitches:=0; var speakers:Dictionary={}
	for line in lines:
		transcript.append("MOURN [%s] %s" % [String(line.get("speaker","")) if String(line.get("speaker",""))!="" else "—",String(line.get("text",""))])
		if String(line.get("role",""))=="official":
			voiced+=1; speakers[String(line.speaker)]=true
			for row in candidates:
				if String((row as Dictionary).get("name",""))==String(line.speaker): pitches+=1
	_check(voiced>=3,"the court mourns and candidates speak (%d voiced lines)" % voiced)
	_check(pitches>=2,"at least two candidates speak for themselves (%d)" % pitches)
	_check(lines.any(func(l:Variant)->bool:return String((l as Dictionary).get("text","")).contains(chief_given)),"the dead are named in the mourning")
	var options:=Hall.options(String(opened.id))
	var choose_ids:Array=options.filter(func(o:Dictionary)->bool:return String(o.id).begins_with("choose:")).map(func(o:Dictionary)->String:return String(o.id))
	_check(choose_ids.size()>=2,"the god chooses among at least two candidates (%d)" % choose_ids.size())
	# Choose someone other than the one already acting.
	var acting:=_office_holder("Steward")
	var pick:=""
	for option_id in choose_ids:
		if int(String(option_id).trim_prefix("choose:"))!=int(acting.get("person_id",0)): pick=String(option_id); break
	if pick=="": pick=String(choose_ids[0])
	var chosen_pid:=int(pick.trim_prefix("choose:"))
	var result:Dictionary=modal.choose(pick) if is_instance_valid(modal) else Hall.resolve(String(opened.id),pick)
	transcript.append("CHOSE %s → %s" % [pick,String(result.get("outcome",""))])
	_check(bool(result.get("ok",false)),"the choice resolves: %s" % String(result.get("outcome","")))
	_check(int(_office_holder("Steward").get("person_id",0))==chosen_pid,"GovernmentPeopleSystem appointed the chosen successor")
	_check(String(Lives.remembered()[0].get("successor",""))!="","the Remembered roll records who followed")
	_check(heard.any(func(e:Dictionary)->bool:return String(e.kind)=="succession"),"the chronicle hook heard the succession")
	for line in (Hall.find(String(opened.id)).get("lines",[]) as Array).slice(lines.size()):
		transcript.append("AFTER [%s] %s" % [String(line.get("speaker","")) if String(line.get("speaker",""))!="" else "—",String(line.get("text",""))])
	if is_instance_valid(modal): modal.queue_free()
	director.queue_free(); terrain.queue_free()
	await _frames(2)
	_test_portraits()

func _test_typed_choice()->void:
	## Online the god can simply say who; the same words pick the same option offline.
	var pathfinder:=_office_holder("ChiefScout")
	if pathfinder.is_empty(): _check(false,"a Pathfinder holds office"); return
	for record in GovernmentPeopleSystem.people:
		if int(record.get("person_id",0))==int(pathfinder.person_id): record["death_age_years"]=float(GovernmentPeopleSystem.age_years(record))-0.5
	_advance(int(GameState.elapsed_days)+31)
	var mourning:Dictionary={}
	for m in Hall.matters():
		if String(m.get("situation_type",""))=="mourning": mourning=m
	_check(not mourning.is_empty(),"the Pathfinder's death is mourned too")
	if mourning.is_empty(): return
	var opened:=Hall.open_matter(String(mourning.id))
	var rows:Array=((opened.situation as Dictionary).mourning as Dictionary).candidates
	var last:Dictionary=rows[rows.size()-1]
	var words:="Let %s walk the far paths for us now." % EraNames.given_of(String(last.name))
	var option:=Lives.typed_choice(String(opened.id),words)
	_check(option=="choose:%d" % int(last.pid),"typed words name the candidate: %s -> %s" % [words,option])
	_check(Lives.typed_choice(String(opened.id),"Not yet; we will wait.")=="mourn_only","typed words can defer the choice")
	var result:=Hall.resolve(String(opened.id),option)
	_check(bool(result.get("ok",false)) and int(_office_holder("ChiefScout").get("person_id",0))==int(last.pid),"the typed choice appoints them")

func _issue(order_text:String)->void:
	var city:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city)
	var reading:=PronouncementInterpreter._local_interpretation(order_text,{"settlement":{"id":city}})
	var order:=AdvisorSystem.begin_civic_directive(order_text,city,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(order_text,reading,order,city,int(leader.get("person_id",0)))
	if String(resolved.get("status","")) in ["awaiting_clarification","awaiting_confirmation"]:
		var confirm:=AdvisorSystem.begin_civic_directive("Yes, do it.",city,leader)
		AdvisorSystem.resolve_civic_directive("Yes, do it.",PronouncementInterpreter._local_interpretation("Yes, do it."),confirm,city,int(leader.get("person_id",0)))

func _test_orders_and_callbacks()->void:
	var start:=int(GameState.elapsed_days)
	var before_orders:=(Lives.state().orders as Array).size()
	for text in ORDERS:
		_issue(String(text))
		_advance(int(GameState.elapsed_days)+7)
	var noted:=(Lives.state().orders as Array).size()-before_orders
	_check(noted==ORDERS.size(),"every order is remembered (%d of %d)" % [noted,ORDERS.size()])
	var rites:=Lives.active_rites()
	_check(not rites.is_empty() and rites.size()<=Lives.RITES_VISIBLE,"a rite burns on the map, capped at %d (%d)" % [Lives.RITES_VISIBLE,rites.size()])
	# The rite is drawn: a handful of meshes near the camp, never more than three rites.
	var host:=Node3D.new(); add_child(host)
	GameState.settlement_completed=["Hearth Circle"]
	RiteMarks.refresh(host)
	var marks:=host.get_node_or_null(RiteMarks.NODE_NAME)
	_check(marks!=null and marks.get_child_count()>=1 and marks.get_child_count()<=Lives.RITES_VISIBLE,"rite marks are drawn and capped (%d)" % (marks.get_child_count() if marks!=null else -1))
	host.queue_free()
	# Every order comes back to court within 180 days.
	_advance(start+ORDERS.size()*7+181)
	var callbacks:=Lives.chronicle(80,"callback")
	_check(callbacks.size()>=ORDERS.size(),"each order produced a callback line (%d of %d)" % [callbacks.size(),ORDERS.size()])
	for entry in callbacks.slice(0,3): transcript.append("CALLBACK day %d: %s" % [int(entry.day),String(entry.text)])
	var matters:=Hall.matters().filter(func(m:Dictionary)->bool:return String(m.get("situation_type",""))=="callback")
	_check(not matters.is_empty(),"callbacks wait as court matters")
	if not matters.is_empty():
		var opened:=Hall.open_matter(String(matters[0].id))
		var lines:Array=opened.get("lines",[]) if opened.has("lines") else Hall.find(String(opened.id)).get("lines",[])
		lines=Hall.find(String(opened.id)).get("lines",[])
		_check(not lines.is_empty(),"the callback is spoken when summoned")
		var result:=Hall.resolve(String(opened.id),"praise_work")
		_check(bool(result.get("ok",false)),"a callback can be answered")

func _test_omens()->void:
	## Demand rain on many days; an omen follows only when the real weather
	## turned wetter within the window, never otherwise.
	var rites:=0; var omens:=0; var false_omens:=0
	var day:=int(GameState.elapsed_days)
	for trial in 9:
		var before:=Lives.chronicle(80,"omen").size()
		var officials:=Hall._officials()
		var love_before:=Divine.love_of(officials[0]) if not officials.is_empty() else 0.0
		var dread_before:=Divine.dread_of(officials[0]) if not officials.is_empty() else 0.0
		_issue("Make it rain on the dry fields.")
		rites+=1
		var omen:Dictionary=(Lives.state().omens as Array)[0]
		var expected:=false
		for d in range(day+1,int(omen.until)+1):
			if Lives.sky_agrees(omen,d): expected=true; break
		_advance(int(omen.until)+2)
		var fired:=Lives.chronicle(80,"omen").size()>before
		if fired: omens+=1
		if fired and not expected: false_omens+=1
		_check(fired==expected,"omen %d fires exactly when the weather agrees (fired %s, weather %s)" % [trial,str(fired),str(expected)])
		if fired and not officials.is_empty():
			var person:=GovernmentPeopleSystem.person_snapshot(int(officials[0].person_id))
			_check(Divine.love_of(person)>love_before or Divine.dread_of(person)>dread_before,"an omen moves love and dread")
			if omens==1: transcript.append("OMEN %s" % String(Lives.chronicle(1,"omen")[0].text))
		day=int(GameState.elapsed_days)+20
		_advance(day)
	transcript.append("OMENS %d of %d rain rites (false omens %d)" % [omens,rites,false_omens])
	_check(omens*3>=rites,"at least one omen per three rites (%d of %d)" % [omens,rites])
	var impossible:={"day":day,"until":day+30,"wish":"dead","weather":1.0,"season":0.0,"health":0.9,"state":"watching"}
	var never:=true
	for d in range(day,day+31):
		if Lives.sky_agrees(impossible,d): never=false
	_check(never,"the dead are never raised")

func _test_rivals()->void:
	for civ in CivilizationSystem.civilizations:
		var id:=String(civ.get("id",""))
		Divine.add_civ_dread(id,0.4); Divine.add_civ_dread(id,0.4)
		var stance:=Lives.rival_stance(id)
		transcript.append("RIVAL %s dread %.2f → %s" % [String(civ.get("name",id)),Lives.rival_dread(id),stance])
		match stance:
			"tribute": _check(Lives.dread_weight("gift_goods",id)>1.5 and Lives.dread_weight("tribute_demand",id)<0.6,"%s answers dread with gifts" % id)
			"provoke": _check(Lives.dread_weight("test_of_resolve",id)>1.5,"%s answers dread with a test" % id)
			"avoid": _check(Lives.dread_weight("tribute_demand",id)<0.6,"%s keeps away" % id)
	var before:=Lives.chronicle(80,"rival").size()
	var day:=int(GameState.elapsed_days)
	day+=10-posmod(day,10)
	_advance(day)
	_check(Lives.chronicle(80,"rival").size()>before,"rivals act on the god's dread")
	for entry in Lives.chronicle(3,"rival"): transcript.append("RIVAL %s" % String(entry.text))
	var tribute:Array=(Hall.state().occasions as Array).filter(func(o:Variant)->bool:return o is Dictionary and String(o.get("type","")) in ["dread_tribute","dread_test"])
	var avoided:=Lives.chronicle(80,"rival").any(func(e:Dictionary)->bool:return String(e.title).ends_with("Keep Away"))
	_check(not tribute.is_empty() or avoided,"dread becomes tribute, a test, or distance")

func _test_save()->void:
	var payload:=ForeignDiplomacy.export_state()
	var round:Variant=JSON.parse_string(JSON.stringify(payload))
	_check(round is Dictionary and Hall.validate_state((round as Dictionary).get("audiences",{})),"the saved hall state validates after a JSON round trip")
	var old:Dictionary=(payload.get("audiences",{}) as Dictionary).duplicate(true)
	old.erase("lives")
	_check(Hall.validate_state(old),"an older save without lives still validates")
	var bad:Dictionary=(payload.get("audiences",{}) as Dictionary).duplicate(true)
	bad["lives"]={"remembered":"nope"}
	_check(not Hall.validate_state(bad),"a corrupted lives block is rejected")

func _hear(entry:Dictionary)->void:
	heard.append(entry)

func _finish()->void:
	Lives.remove_listener(_hear)
	for line in transcript: print(line)
	if failures.is_empty():
		print("COURT_LIVES_PROBE PASS")
		get_tree().quit(0)
		return
	print("COURT_LIVES_PROBE FAIL (%d)" % failures.size())
	get_tree().quit(1)
