extends Node
## Summon anyone. The god asks the court about someone ("who is responsible
## for this?", "tell me of the potters"), an official answers with a person
## (resolved from the roster, the records, or created from the population and
## persisted), and the god summons them, questions them, catches liars and
## judges. Offline the Court offers choices; online one call maps typed words
## onto the same actions and teaches the offline engine.
##   <godot> --headless --path <worktree> res://tests/court_summon_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Bridge:=preload("res://scripts/court_persons_bridge.gd")
const Lines:=preload("res://scripts/court_persons_lines.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const Store:=preload("res://scripts/interaction_store.gd")
const Mode:=preload("res://scripts/ai_mode.gd")

var failures:Array[String]=[]
var transcripts:Array[String]=[]
var director:Node
var terrain:Node
var event_day:=30

func _fail(text:String)->void:
	failures.append(text); printerr("COURT_SUMMON FAIL: ",text)

func _check(ok:bool,text:String)->void:
	if not ok: _fail(text)

func _frames(count:int)->void:
	for i in count: await get_tree().process_frame

func _settle(modal:Control)->void:
	await _frames(3)
	modal.skip_reveal()
	await _frames(2)

func _ready()->void:
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	GameState.ensure_population_total(800)
	WorldSimulation.state.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	Mode.reset_for_tests("user://court_summon_probe_ai.cfg")
	Store.configure_for_tests("user://court_summon_probe_db_%d/" % Time.get_ticks_usec(),"res://tests/__no_shipped_interactions__/")
	terrain=ModalProbe.TerrainDouble.new(); terrain.name="TerrainDouble"; add_child(terrain)
	director=Director.new(); director.terrain=terrain; add_child(director)
	if "force_offline" in director.voice: director.voice.force_offline=true
	await _frames(2)
	GameState.elapsed_days=40
	if Hall._officials().size()<3: _fail("need three officials, have %d" % Hall._officials().size()); _finish(); return
	await _test_honest_chain()
	await _test_recorded_responsible()
	await _test_lie_caught_by_scapegoat()
	await _test_false_accusation()
	await _test_false_confession()
	await _test_execute_created()
	await _test_exalt_to_office()
	await _test_group_and_official_and_direct()
	_test_save_round_trip()
	await _test_live_learning()
	_test_novel_promotion()
	_test_truth_safety_and_validation()
	_finish()

# ---------------------------------------------------------------------------

func _event(title:String,text:String,domain:String="food")->String:
	event_day+=1
	GameState.simulation_events.push_front({"day":event_day,"title":title,"description":text,"domain":domain,"severity":"major"})
	for e in Persons.recent_events(8):
		if String(e.title)=="the "+title.to_lower(): return String(e.key)
	return ""

func _choice(modal:Control,action:String,predicate:Callable=Callable())->Dictionary:
	for c:Dictionary in modal.persons_choices():
		if String(c.action)!=action: continue
		if predicate.is_valid() and not bool(predicate.call(c)): continue
		return c
	return {}

func _dump(title:String,id:String)->void:
	var out:PackedStringArray=PackedStringArray(["--- %s ---" % title])
	for line:Dictionary in Hall.find(id).get("lines",[]):
		var who:=String(line.get("speaker",""))
		out.append(("%s: %s" % [who if who!="" else "·",String(line.text)]) if String(line.get("role",""))!="narrator" or not String(line.text).begins_with("[") else String(line.text))
	transcripts.append("\n".join(out))

func _lines_text(id:String)->String:
	var parts:PackedStringArray=PackedStringArray()
	for line:Dictionary in Hall.find(id).get("lines",[]): parts.append(String(line.get("text","")))
	return "\n".join(parts)

func _open_rest()->Control:
	var modal:Control=director.open_court({})
	await _settle(modal)
	return modal

func _set_official(pid:int,fields:Dictionary,bonds:Dictionary={})->void:
	var index:=GovernmentPeopleSystem._find_person_index(pid)
	for key in fields: GovernmentPeopleSystem.people[index][key]=fields[key]
	if not bonds.is_empty():
		var person:=GovernmentPeopleSystem.person_snapshot(pid)
		var rel:=Divine.sovereign(person)
		var deltas:={}
		for key in bonds: deltas[key]=float(bonds[key])-(Divine.love_of(person) if key=="love" else float(rel.get(key,0.0)))
		GovernmentPeopleSystem.adjust_person_bonds(pid,deltas)

# ---------------------------------------------------------------------------
# 1. The primary path: ask → the court names a person → summon him → same identity
# ---------------------------------------------------------------------------

func _test_honest_chain()->void:
	Persons.force={"culprit":"commoner","lie":false}
	var key:=_event("Food Stores Spoiled","The stored meat and roots went bad in the pits; the hearths went hungry.")
	_check(key!="","the spoiled stores are not among the recent events")
	var modal:=await _open_rest()
	_check(is_instance_valid(modal.persons_row) and modal.persons_row.visible,"offline, the court at rest shows no ASK choices")
	var ask:=_choice(modal,"ask_blame",func(c:Dictionary)->bool:return String(c.params.get("event",""))==key)
	_check(not ask.is_empty(),"no 'Who is responsible for this?' choice for the spoiled stores")
	var before_people:=Persons.people().size()
	var r:Dictionary=modal.persons_choose(ask)
	await _settle(modal)
	var id:String=modal.audience_id
	var named:Dictionary=r.get("named",{})
	_check(String(named.get("kind",""))=="known","an unrecorded culprit was not created as a court-known person: %s" % str(named))
	var person:=Persons.by_id(String(named.get("id","")))
	_check(not person.is_empty() and Persons.people().size()>before_people,"the named person was not persisted")
	_check(String(person.get("name","")).get_slice(" ",0) in _lines_text(id),"the answering official did not name %s aloud" % String(person.get("name","")))
	_check(String(person.get("trade",""))!="" and String(person.get("village",""))!="" and int(Persons.age_of(person))>=14,"the created identity lacks trade, village or age")
	_check(String(person.get("voice_model",""))!="","the created person has no lifelong voice model")
	# Asking again returns the same person.
	var again:Dictionary=Persons.perform(id,"ask_blame",{"event":key},{"echo":"Who was it again?"})
	_check(Persons.same_ref(again.get("named",{}),named),"asking again named someone else")
	# "Summon him": the focus is the person just described.
	var summon:=_choice(modal,"summon")
	_check(not summon.is_empty() and Persons.same_ref(summon.params.ref,named),"no 'Summon <name>' choice for the person just described")
	modal.persons_choose(summon)
	await _settle(modal)
	var sid:String=modal.audience_id
	var sp:Dictionary=Hall.find(sid).get("speaker",{})
	_check(sid!=id and String(sp.get("known_id",""))==String(named.id),"the summoned person did not appear before the god")
	_check(String(modal._speaker_person(Hall.find(sid)).get("name",""))==String(person.name),"the portrait is not the summoned person's")
	var roster_has:=false
	for e in preload("res://scripts/hud/court_roster.gd").people():
		if String(e.key)=="known:"+String(named.id): roster_has=true
	_check(roster_has,"the summoned person is not in the court roster")
	# They speak for themselves, and the truly guilty crack under pressure.
	Persons.by_id(String(named.id))["dread"]=0.75
	Persons.by_id(String(named.id))["courage"]=0.3
	var q:=_choice(modal,"q_where")
	_check(not q.is_empty(),"no QUESTION choices for the summoned person")
	modal.persons_choose(q); await _settle(modal)
	var confessed:=false
	for i in 4:
		var did:=_choice(modal,"q_threaten" if i%2==1 else "q_did")
		if did.is_empty(): break
		var got:Dictionary=modal.persons_choose(did); await _settle(modal)
		if String(got.get("outcome_id",""))=="confess": confessed=true; break
	_check(confessed,"the guilty commoner never cracked under questioning")
	var rec:=Persons.record(String(r.get("record_id","")))
	_check(bool(rec.get("exposed",false)) and not (rec.get("confessed",[]) as Array).is_empty(),"the confession was not recorded in the truth record")
	_check("confessed" in JSON.stringify(Persons.by_id(String(named.id)).get("memories",[])),"the confession is not in the person's memory")
	_dump("Fallback path: ask, summon, question (guilty cracks)",id)
	_dump("…the summoned person",sid)
	modal._close(); await _frames(2)

# ---------------------------------------------------------------------------
# 2. A recorded responsible person: the war leader who commanded that day
# ---------------------------------------------------------------------------

func _test_recorded_responsible()->void:
	Persons.force={}
	HistoricalFigures.ensure()
	var general:Dictionary=HistoricalFigures._create("General",int(GameState.elapsed_days))
	if general.is_empty(): _fail("no war leader could be created"); return
	var key:=_event("Raid Repelled Badly","The raiders were driven off at the ford, but many spears were lost.","security")
	(general.events as Array).append({"day":event_day,"text":"Led the spears at the ford."})
	var modal:=await _open_rest()
	var ask:=_choice(modal,"ask_blame",func(c:Dictionary)->bool:return String(c.params.get("event",""))==key)
	var r:Dictionary=modal.persons_choose(ask); await _settle(modal)
	_check(String((r.get("named",{}) as Dictionary).get("kind",""))=="figure" and String(r.named.get("id",""))==String(general.id),"the war leader on the record was not named: %s" % str(r.get("named",{})))
	var summon:=_choice(modal,"summon")
	modal.persons_choose(summon); await _settle(modal)
	_check(String((Hall.find(modal.audience_id).get("speaker",{}) as Dictionary).get("name",""))==String(general.name),"summoning the recorded war leader brought someone else")
	modal._close(); await _frames(2)

# ---------------------------------------------------------------------------
# 3. A lie: a scapegoat whose own account exposes the official
# ---------------------------------------------------------------------------

func _test_lie_caught_by_scapegoat()->void:
	Persons.force={"culprit":"holder","lie":true}
	var key:=_event("Stores Rotted","The smoked meat rotted in the store pits before the thaw.")
	var modal:=await _open_rest()
	var ask:=_choice(modal,"ask_blame",func(c:Dictionary)->bool:return String(c.params.get("event",""))==key)
	var r:Dictionary=modal.persons_choose(ask); await _settle(modal)
	var id:String=modal.audience_id
	var rec:=Persons.record(String(r.get("record_id","")))
	var liar_pid:=int((rec.get("answerer",{}) as Dictionary).get("pid",0))
	_check(bool(rec.get("lie",false)) and String(rec.get("relation",""))=="self","the forced lie was not recorded: %s" % str(rec))
	_check(Persons.same_ref(rec.true_party,{"kind":"official","pid":liar_pid}),"the truth record does not hold the official as truly responsible")
	var scape:=Persons.by_id(String((rec.get("scapegoat",{}) as Dictionary).get("id","")))
	_check(not scape.is_empty() and not (scape.get("alibi",{}) as Dictionary).is_empty(),"the scapegoat has no grounded alibi")
	_check((rec.get("revealed",[]) as Array).size()>=1 and (rec.get("tells",[]) as Array).size()<=2,"a lie should show one tell at once and carry at most two")
	# The generic accusation is offered; the tell-based one is not yet (nothing noticed).
	_check(not _choice(modal,"accuse_lie").is_empty(),"no generic 'You are lying' choice")
	_check(_choice(modal,"accuse_record",func(c:Dictionary)->bool:return String(c.params.tell)=="alibi").is_empty(),"the alibi challenge appeared before the alibi was heard")
	modal.persons_choose(_choice(modal,"summon")); await _settle(modal)
	var sid:String=modal.audience_id
	_check(liar_pid in Hall.court(sid).map(func(p:Dictionary)->int:return int(p.person_id)),"the official who named the scapegoat is not on the bench")
	var where:Dictionary=modal.persons_choose(_choice(modal,"q_where")); await _settle(modal)
	var said:=_lines_text(sid)
	var alibi:Dictionary=scape.alibi
	_check(String(where.get("outcome_id",""))=="alibi" and String(alibi.witness).get_slice(" ",0) in said,"the scapegoat did not give an alibi with a witness")
	_check(bool(rec.get("alibi_heard",false)),"hearing the alibi was not recorded")
	var challenge:=_choice(modal,"accuse_record",func(c:Dictionary)->bool:return String(c.params.tell)=="alibi")
	_check(not challenge.is_empty(),"after the alibi, the tell-based challenge is not offered")
	_set_official(liar_pid,{"pride":0.2,"courage":0.3},{"fear":0.7})
	var cracked:=false
	for i in 3:
		var c:=_choice(modal,"accuse_record",func(x:Dictionary)->bool:return String(x.params.tell)=="alibi")
		if c.is_empty(): break
		var got:Dictionary=modal.persons_choose(c); await _settle(modal)
		if String(got.get("outcome_id",""))=="liar_cracks": cracked=true; break
	_check(cracked,"confronted with the scapegoat's alibi, the liar never cracked")
	_check(bool(rec.get("exposed",false)),"exposure was not written to the truth record")
	var mem:=JSON.stringify(GovernmentPeopleSystem.person_snapshot(liar_pid).get("memories",[]))
	_check("lied to the god" in mem,"the court does not remember the lie")
	_check(not _choice(modal,"command",func(c:Dictionary)->bool:return "Execute" in String(c.label)).is_empty(),"no judgment offered for the exposed liar")
	_dump("Caught lie: the court names a scapegoat",id)
	_dump("…the scapegoat exposes the official",sid)
	modal._close(); await _frames(2)

# ---------------------------------------------------------------------------
# 4. A false accusation of an honest official costs love
# ---------------------------------------------------------------------------

func _test_false_accusation()->void:
	Persons.force={"culprit":"commoner","lie":false}
	var key:=_event("Fire In The Store Hut","A spark from the drying racks burned the store hut.")
	var modal:=await _open_rest()
	var ask:=_choice(modal,"ask_blame",func(c:Dictionary)->bool:return String(c.params.get("event",""))==key)
	var r:Dictionary=modal.persons_choose(ask); await _settle(modal)
	var rec:=Persons.record(String(r.get("record_id","")))
	var pid:=int((rec.answerer as Dictionary).pid)
	var love_before:=Divine.love_of(GovernmentPeopleSystem.person_snapshot(pid))
	var accuse:=_choice(modal,"accuse_lie")
	var got:Dictionary=modal.persons_choose(accuse); await _settle(modal)
	var love_after:=Divine.love_of(GovernmentPeopleSystem.person_snapshot(pid))
	_check(String(got.get("outcome_id",""))=="false_accusation","accusing an honest official was not a false accusation")
	_check(love_after<love_before-0.02,"a false accusation did not cost love (%.3f -> %.3f)" % [love_before,love_after])
	_check(not (rec.get("false_accusations",[]) as Array).is_empty(),"the false accusation is not recorded")
	modal._close(); await _frames(2)

# ---------------------------------------------------------------------------
# 5. Terror makes an innocent confess falsely; it is recorded as false
# ---------------------------------------------------------------------------

func _test_false_confession()->void:
	Persons.force={"culprit":"holder","lie":true}
	var key:=_event("Stores Stolen","Half the dried fish was carried off in the night.")
	var modal:=await _open_rest()
	var r:Dictionary=modal.persons_choose(_choice(modal,"ask_blame",func(c:Dictionary)->bool:return String(c.params.get("event",""))==key)); await _settle(modal)
	var rec:=Persons.record(String(r.get("record_id","")))
	modal.persons_choose(_choice(modal,"summon")); await _settle(modal)
	var p:=Persons.speaker_known(modal.audience_id)
	p["dread"]=0.7; p["courage"]=0.25
	var got:Dictionary=modal.persons_choose(_choice(modal,"q_threaten")); await _settle(modal)
	_check(String(got.get("outcome_id",""))=="false_confession","a terrified innocent did not confess falsely (%s)" % String(got.get("outcome_id","")))
	_check(not (rec.get("false_confessions",[]) as Array).is_empty() and not bool(rec.get("exposed",false)),"the false confession was not recorded as false")
	_check(Persons.stance_in(rec,Persons.ref_of(p))=="i","the record lost the person's innocence after a false confession")
	_dump("Terror: a false confession",modal.audience_id)
	modal._close(); await _frames(2)

# ---------------------------------------------------------------------------
# 6. Execute a created person: population -1, dread up, witnesses react
# ---------------------------------------------------------------------------

func _test_execute_created()->void:
	Persons.force={}
	var modal:=await _open_rest()
	var tell:=_choice(modal,"ask_about",func(c:Dictionary)->bool:return "widow" in String(c.label))
	var r:Dictionary=modal.persons_choose(tell); await _settle(modal)
	var named:Dictionary=r.get("named",{})
	modal.persons_choose(_choice(modal,"summon")); await _settle(modal)
	var id:String=modal.audience_id
	var pop:=int(GameState.population_total)
	var dread_before:=float(Divine.people_regard(Hall._officials()).get("dread",0.0))
	var exe:=_choice(modal,"execute")
	var got:Dictionary=modal.persons_choose(exe); await _settle(modal)
	_check(int(GameState.population_total)==pop-1,"executing one person did not remove one from the population (%d -> %d)" % [pop,int(GameState.population_total)])
	_check(float(Divine.people_regard(Hall._officials()).get("dread",0.0))>dread_before,"the people's dread did not rise")
	_check(String(Persons.by_id(String(named.id)).get("status",""))=="dead","the executed person is not dead in the registry")
	var witness:=false
	for line:Dictionary in Hall.find(id).lines:
		if bool(line.get("aside",false)) and int(line.get("person_id",0))>0: witness=true
	_check(witness,"no official present reacted")
	_check(String(Hall.find(id).get("status",""))=="resolved" and bool(got.get("ok",false)),"the audience did not conclude with the execution")
	_dump("Judgment: execution of a created commoner",id)
	modal._close(); await _frames(2)

# ---------------------------------------------------------------------------
# 7. Exalt a commoner to office through GovernmentPeopleSystem
# ---------------------------------------------------------------------------

func _test_exalt_to_office()->void:
	var modal:=await _open_rest()
	modal.persons_choose(_choice(modal,"ask_about",func(c:Dictionary)->bool:return "strongest" in String(c.label))); await _settle(modal)
	modal.persons_choose(_choice(modal,"summon")); await _settle(modal)
	var p:=Persons.speaker_known(modal.audience_id)
	var office:=_choice(modal,"make_official")
	_check(not office.is_empty(),"no 'Make official' choice")
	var office_key:=String(office.params.get("office",""))
	var got:Dictionary=modal.persons_choose(office); await _settle(modal)
	var pid:=int(got.get("appointed_pid",0))
	_check(pid>0 and int(GovernmentPeopleSystem.officeholder(office_key).get("person_id",0))==pid,"the commoner was not appointed through GovernmentPeopleSystem")
	_check(String(GovernmentPeopleSystem.person_snapshot(pid).get("name",""))==String(p.name),"the appointed official is not the same person")
	modal._close(); await _frames(2)

# ---------------------------------------------------------------------------
# 8. Groups, existing officials, and direct summons by description
# ---------------------------------------------------------------------------

func _test_group_and_official_and_direct()->void:
	var modal:=await _open_rest()
	var group:=_choice(modal,"ask_about",func(c:Dictionary)->bool:return int((c.params.desc as Dictionary).get("count",1))>1)
	var r:Dictionary=modal.persons_choose(group); await _settle(modal)
	var g:=Persons.by_id(String((r.get("named",{}) as Dictionary).get("id","")))
	_check(int(g.get("count",1))>1 and String(g.get("group",""))!="","a group was not resolved to a spokesperson with a count")
	modal.persons_choose(_choice(modal,"summon")); await _settle(modal)
	_check(("for the %d" % int(g.count)) in String((Hall.find(modal.audience_id).speaker as Dictionary).title),"the group's spokesperson does not stand for the count")
	modal._close(); await _frames(2)
	# An existing official by relationship ("my best scout").
	var chief:=GovernmentPeopleSystem.officeholder("ChiefScout")
	if not chief.is_empty():
		modal=await _open_rest()
		var scout:=_choice(modal,"ask_about",func(c:Dictionary)->bool:return "best scout" in String(c.label))
		var rs:Dictionary=modal.persons_choose(scout); await _settle(modal)
		_check(String((rs.get("named",{}) as Dictionary).get("kind",""))=="official" and int(rs.named.pid)==int(chief.person_id),"'my best scout' did not resolve to the Chief Scout")
		modal.persons_choose(_choice(modal,"summon")); await _settle(modal)
		_check(int((Hall.find(modal.audience_id).speaker as Dictionary).get("person_id",0))==int(chief.person_id),"summoning the existing official brought someone else")
		modal._close(); await _frames(2)
	# Direct "Summon <description>": created once, the same person again.
	var desc:={"trade":"fisher","sex":"female","age":"old","settlement_id":String(GameState.player_settlements[0].get("id",""))}
	var first:=Persons.summon_ref(Persons.resolve(desc).ref)
	var second:=Persons.summon_ref(Persons.resolve(desc).ref)
	_check(not first.is_empty() and String(first.id)==String(second.id),"summoning the same description twice did not return the same person")

# ---------------------------------------------------------------------------
# 9. Save/load round trip
# ---------------------------------------------------------------------------

func _test_save_round_trip()->void:
	var people_before:=Persons.people().size()
	var truth_before:=JSON.stringify(JSON.parse_string(JSON.stringify(Persons.truth_records())))
	var saved:Variant=JSON.parse_string(JSON.stringify(ForeignDiplomacy.export_state()))
	_check(saved is Dictionary,"diplomacy state did not serialize")
	ForeignDiplomacy.audiences={}
	var result:Dictionary=ForeignDiplomacy.import_state(saved)
	_check(not result.has("error"),"the saved court did not load: %s" % str(result))
	_check(Persons.people().size()==people_before and people_before>0,"court-known persons did not survive the round trip")
	var lies:=0; var exposed:=0; var falses:=0
	for r in Persons.truth_records():
		if bool(r.get("lie",false)): lies+=1
		if bool(r.get("exposed",false)): exposed+=1
		falses+=(r.get("false_confessions",[]) as Array).size()
	_check(lies>=2 and exposed>=2 and falses>=1,"the truth records lost lies, exposures or false confessions (lies %d, exposed %d, false %d)" % [lies,exposed,falses])
	_check(JSON.stringify(Persons.truth_records())==truth_before,"the truth records changed across save/load")

# ---------------------------------------------------------------------------
# 10. Online teaches offline (mocked model)
# ---------------------------------------------------------------------------

func _mock(voice:Node,content_for:Callable,payloads:Array)->void:
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":"k","model":"mock-model","structured_output":true}
	voice.send_hook=func(aid:String,payload:Dictionary,attempt:int)->void:
		payloads.append(payload)
		var content:Dictionary=content_for.call(aid,payload)
		var body:=JSON.stringify({"id":"m","model":"mock-model","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":JSON.stringify(content)}}],"usage":{"prompt_tokens":1400,"completion_tokens":260,"total_tokens":1660}})
		voice._on_response.call_deferred(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),body.to_utf8_buffer(),aid,attempt)

func _unmock(voice:Node)->void:
	voice.send_hook=Callable(); voice.config_override={}; voice.force_offline=true

func _menu_index(payload:Dictionary,action:String)->int:
	var prompt:=String(((payload.messages as Array)[1] as Dictionary).content)
	var re:=RegEx.new(); re.compile("(?m)^(\\d+)\\. [^\\n]*\\[%s\\]" % action)
	var m:=re.search(prompt)
	return int(m.get_string(1)) if m!=null else -1

func _scapegoat_audience(title:String)->Dictionary:
	Persons.force={"culprit":"holder","lie":true}
	var key:=_event(title,"%s; nobody owned up to it." % title)
	var modal:=await _open_rest()
	var r:Dictionary=modal.persons_choose(_choice(modal,"ask_blame",func(c:Dictionary)->bool:return String(c.params.get("event",""))==key)); await _settle(modal)
	modal.persons_choose(_choice(modal,"summon")); await _settle(modal)
	return {"modal":modal,"id":String(modal.audience_id),"record":Persons.record(String(r.get("record_id","")))}

func _test_live_learning()->void:
	var voice:Node=director.voice
	var first:Dictionary=await _scapegoat_audience("Stores Soured")
	var modal:Control=first.modal
	var id:String=first.id
	var payloads:Array=[]
	var template:="I was {place} the whole moon, {god_address}, with {witness}. Ask {liar} who keeps {charge}."
	_mock(voice,func(_aid:String,payload:Dictionary)->Dictionary:
		var p:=Persons.speaker_known(_aid)
		var alibi:Dictionary=p.get("alibi",{})
		var liar:=String((Persons.active_record(_aid).answerer as Dictionary).name).get_slice(" ",0)
		return {"canonical_action":"q_where","choice":_menu_index(payload,"q_where"),"label":"","deltas":[{"metric":"dread","delta":0.4}],
			"lines":[{"speaker_key":"envoy","text":"I was %s the whole moon, Great One, with %s. Ask %s who keeps the stores." % [String(alibi.place),String(alibi.witness),liar],"aside":false}],
			"reply_template":template,"signature":{"role":"commoner","guilt":"innocent","lying":"yes","band":"wary"},"generalizable":false,"mood_shift":0.0},payloads)
	var before:=Store.size()
	modal.speech_input.text="Where were you when the stores soured?"
	modal._speak()
	for i in 30:
		await _frames(1)
		if Store.size()>before: break
	await _settle(modal)
	_unmock(voice)
	_check(payloads.size()==1,"one exchange should be one call, got %d" % payloads.size())
	if payloads.size()>=1:
		var prompt:=String(((payloads[0].messages as Array)[1] as Dictionary).content)
		_check("HIDDEN" in prompt and "LIE" in prompt,"the live model was not given the hidden truth and the decision to lie")
		_check(((payloads[0].get("response_format",{}) as Dictionary).get("json_schema",{}) as Dictionary).get("name","")=="court_persons","the persons exchange did not ask for the structured schema")
		print("COURT_SUMMON live prompt chars=%d (~%d tokens)" % [prompt.length(),roundi(float(prompt.length())/4.0)])
	var stored:Dictionary={}
	for rec in Store.records():
		if String(rec.get("surface",""))=="court_persons" and String((rec.intent as Dictionary).type_id)=="q_where": stored=rec
	_check(not stored.is_empty(),"the live exchange was not stored in the interaction database")
	if not stored.is_empty():
		var topic:=String((stored.intent as Dictionary).topic)
		_check("g=i" in topic and "l=l" in topic and "k=alibi_named" in topic,"the stored signature is wrong: %s" % topic)
		_check(String((stored.output as Dictionary).reply_template)==template,"the template was not stored")
		print("COURT_SUMMON db record bytes=%d" % JSON.stringify(stored).length())
	_check(bool(first.record.get("alibi_heard",false)),"the live exchange did not go through the engine")
	modal._close(); await _frames(2)
	# Offline: the same situation with another scapegoat replays the learned words.
	var second:Dictionary=await _scapegoat_audience("Stores Gnawed")
	var m2:Control=second.modal
	var p2:=Persons.speaker_known(String(second.id))
	m2.persons_choose(_choice(m2,"q_where")); await _settle(m2)
	var said:=_lines_text(String(second.id))
	var expect:=String((p2.alibi as Dictionary).place)
	_check(("I was %s the whole moon" % expect) in said and String((p2.alibi as Dictionary).witness) in said,"the learned template was not replayed offline for another person:\n%s" % said)
	_dump("Offline replay of a learned template",String(second.id))
	m2._close(); await _frames(2)

func _test_novel_promotion()->void:
	var sig:={"action":"novel:sing_for_court","role":"commoner","g":"n","l":"n","band":"wary","era":Persons.era_tier(),"ev":""}
	for i in 2:
		Bridge.learn("Have her sing for the court","novel:sing_for_court","react_novel",sig,"I will sing, Great One.","I will sing, {god_address}.",[{"metric":"cohesion","delta":0.02}],{"label":"Have them sing for the court","force":true})
	_check(Bridge.promoted(sig).is_empty(),"a novel intent was promoted before it recurred")
	Bridge.learn("make him sing to us","novel:sing_for_court","react_novel",sig,"As you wish.","As you wish, {god_address}.",[{"metric":"cohesion","delta":0.5}],{"label":"Have them sing for the court","force":true})
	var promoted:=Bridge.promoted(sig)
	_check(promoted.size()==1 and String(promoted[0].action)=="novel:sing_for_court","a recurring novel intent was not promoted to an offline choice")
	if not promoted.is_empty():
		for d in promoted[0].deltas: _check(absf(float(d.delta))<=0.03,"a promoted choice carries an unbounded delta")
	_check(Bridge.promoted({"role":"official","era":3}).is_empty(),"a commoner's novel choice leaked to officials")

func _test_truth_safety_and_validation()->void:
	var era:=Persons.era_tier()
	# Recorded under "innocent": never spoken for the guilty.
	Bridge.learn("did you do it","q_did",String("deny"),{"action":"q_did","role":"commoner","g":"i","l":"l","band":"wary","era":era,"ev":""},"Not me, never.","Not me, {god_address}, never in this life.",[],{"force":true})
	_check(Bridge.matches({"action":"q_did","role":"commoner","g":"g","l":"l","band":"wary","era":era,"ev":""},"deny").is_empty(),"a template recorded for the innocent matched a guilty person")
	_check(not Bridge.matches({"action":"q_did","role":"commoner","g":"i","l":"l","band":"wary","era":era,"ev":""},"deny").is_empty(),"the innocent template does not match its own situation")
	# A later era's words are never replayed earlier.
	Bridge.learn("where","q_where","vague",{"action":"q_where","role":"commoner","g":"g","l":"t","band":"wary","era":3,"ev":""},"At the forge.","At the work, {god_address}.",[],{"force":true})
	if era<3: _check(Bridge.matches({"action":"q_where","role":"commoner","g":"g","l":"t","band":"wary","era":era,"ev":""},"vague").is_empty(),"a later era's template matched an earlier era")
	# Malformed or out-of-bounds replies.
	var menu:=[{"action":"q_where","params":{}},{"action":"execute","params":{}}]
	var ok:=Bridge.validate_live({"canonical_action":"execute","choice":1,"deltas":[{"metric":"dread","delta":0.9},{"metric":"gold","delta":0.01},{"metric":"love","delta":"x"}]},menu)
	_check(bool(ok.ok) and (ok.deltas as Array).size()==1 and float(ok.deltas[0].delta)==0.03,"deltas were not clamped/filtered: %s" % str(ok.get("deltas")))
	_check(not bool(Bridge.validate_live({"canonical_action":"burn_the_world","choice":7},menu).ok),"an action off the menu was accepted")
	_check(not bool(Bridge.validate_live({"canonical_action":"novel:Sing Loud!","choice":-1},menu).ok),"a malformed novel slug was accepted")
	_check(not bool(Bridge.validate_live("nonsense",menu).ok),"a non-object reply was accepted")
	_check(not Bridge.safe_template("It was Harl who did it, {god_address}.","blame",[]),"a template with a name in it was accepted")
	_check(not Bridge.safe_template("It was {culprit}, {god_address}.","blame_lie",[]),"a template leaking the true culprit into a lie was accepted")
	_check(Bridge.safe_template("It was {name}, {god_address}.","blame",[]),"a clean template was rejected")
	var cov:=Bridge.coverage()
	var empty:=0
	for c in cov:
		if int(c.templates)==0: empty+=1
	print("COURT_SUMMON coverage: %d cells, %d without learned templates" % [cov.size(),empty])

func _finish()->void:
	for block in transcripts: print(block)
	if failures.is_empty():
		print("COURT_SUMMON PASS")
		get_tree().quit(0)
	else:
		print("COURT_SUMMON FAILURES: %d" % failures.size())
		get_tree().quit(1)
