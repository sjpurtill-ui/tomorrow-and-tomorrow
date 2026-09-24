extends Node
## Love and dread: the god's wrath and favour in the audience hall.
## Checks the meter and its reads, every act's bounded shifts on the target and
## the watching court, execution and exile through the government, the
## downstream honesty/willingness/sabotage/flight consequences, free-text and
## live-classifier acts, envoy terror, and save round trips (new and legacy).
## Prints a sample offline transcript. Windowed (tools/run_isolated_gpu_probe.ps1)
## it also captures the modal with the meter to res://reports/fear-love/.
##   <godot> --headless --path <worktree> res://tests/fear_love_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const DV:=preload("res://scripts/divine_voice.gd")
const TALKING_DOWN:="(?i)(\\b(dearie|kiddo|sonny|youngster|little one|my boy|my girl|my pet)\\b|[,:]\\s*child\\b)"

var failures:Array[String]=[]
var transcripts:Array[String]=[]
var seen_lines:Dictionary={}
var capture:=false
var out_dir:=""
var director:Node
var terrain:Node

func _fail(text:String)->void:
	failures.append(text); printerr("FEAR_LOVE FAIL: ",text)

func _check(ok:bool,text:String)->void:
	if not ok: _fail(text)

func _frames(count:int)->void:
	for i in count: await get_tree().process_frame

func _wait(modal:Control,id:String,minimum:int,limit:float=6.0)->void:
	var waited:=0.0
	while waited<limit:
		if (Hall.find(id).get("lines",[]) as Array).size()>=minimum and not modal.voice.busy(id): break
		await get_tree().process_frame; waited+=get_process_delta_time()
	modal.skip_reveal()
	await _frames(2)

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for argument in OS.get_cmdline_user_args():
		if argument=="--no-capture": capture=false
	out_dir=ProjectSettings.globalize_path("res://reports/fear-love/")
	if capture: DirAccess.make_dir_recursive_absolute(out_dir)
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	# A town-sized people: enough offices for a court to watch.
	GameState.ensure_population_total(800)
	WorldSimulation.state.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	terrain=ModalProbe.TerrainDouble.new(); terrain.name="TerrainDouble"; add_child(terrain)
	director=Director.new(); director.terrain=terrain; add_child(director)
	if "force_offline" in director.voice: director.voice.force_offline=true
	await _frames(2)
	GameState.elapsed_days=40
	_test_meter()
	if Hall._officials().size()<3: _fail("need three officials, have %d" % Hall._officials().size()); _finish(); return
	await _test_terrify_and_favour()
	await _test_strike_down()
	await _test_cast_out()
	_test_consequences()
	await _test_flight()
	await _test_free_text()
	await _test_live_classifier()
	await _test_envoy()
	_test_saves()
	_finish()

# ---------------------------------------------------------------------------

func _test_meter()->void:
	var cases:=[[0.8,0.6,0.1,"worships"],[0.4,0.7,0.1,"terror"],[0.8,0.1,0.0,"fearless_love"],[0.3,0.7,0.5,"hates_dread"],
		[0.6,0.3,0.0,"reveres"],[0.45,0.1,0.4,"resents"],[0.45,0.4,0.1,"wary"],[0.2,0.1,0.1,"cold"],[0.45,0.1,0.1,"dutiful"]]
	for c in cases:
		var got:=String(Divine.read(float(c[0]),float(c[1]),float(c[2])).id)
		_check(got==String(c[3]),"read(%s) gave %s" % [str(c),got])
	_check(String(Divine.read(0.4,0.7,0.1).read)=="obeys out of terror","terror read text wrong")
	_check(String(Divine.read(0.8,0.6,0.1).read)=="worships you","worship read text wrong")
	_check(String(Divine.read(0.8,0.1,0.0).read)=="loves you and fears nothing","fearless-love read text wrong")
	_check(String(Divine.read(0.45,0.1,0.4).read)=="quietly resents you","resent read text wrong")
	# Legacy record: no love field; love is derived and stays in bounds.
	var person:Dictionary=Hall._officials()[0]
	var rel:Dictionary=Divine.sovereign(person)
	_check(not rel.has("love"),"a fresh official already has a love field")
	var derived:=Divine.love_of(person)
	_check(derived>=0.0 and derived<=1.0 and is_equal_approx(derived,Divine.derived_love(rel)),"legacy love not derived from trust/respect")
	var regard:=Divine.regard(person)
	for key in ["love","dread","read","id","candor","risk","warned"]: _check(regard.has(key),"regard lacks %s" % key)
	var people:=Hall.people_regard()
	_check(people.has("love") and people.has("dread") and String(people.read).begins_with("your people"),"people-wide regard missing: %s" % str(people))

func _bonds(pid:int)->Dictionary:
	var person:=GovernmentPeopleSystem.person_snapshot(pid)
	var rel:=Divine.sovereign(person).duplicate()
	rel["love"]=Divine.love_of(person)
	return rel

func _witness_bonds(ids:Array)->Dictionary:
	var out:={}
	for wid in ids: out[int(wid)]=_bonds(int(wid))
	return out

func _court_ids(id:String)->Array:
	var ids:Array=[]
	for p:Dictionary in Hall.court(id): ids.append(int(p.person_id))
	return ids

func _test_terrify_and_favour()->void:
	var officials:=Hall._officials()
	var target:Dictionary=officials[0]
	var pid:=int(target.person_id)
	var modal:Control=director.summon({"person_id":pid})
	if modal==null: _fail("summoning the first official opened nothing"); return
	var id:=String(modal.audience_id)
	await _wait(modal,id,1)
	# The meter shows in the stage panel.
	var meter:=modal.find_child("RegardMeter",true,false)
	var read:=modal.find_child("RegardRead",true,false) as Label
	_check(meter!=null and read!=null and not read.text.is_empty(),"the modal has no love/dread meter")
	var row:=modal.find_child("DivineRow",true,false)
	var wrath:=row.find_child("Divine_wrath",true,false) if row!=null else null
	var favour:=row.find_child("Divine_favor",true,false) if row!=null else null
	_check(wrath!=null and favour!=null,"the wrath/favour menus are missing")
	if wrath!=null and favour!=null:
		var acts:Array=(wrath.get_meta("actions",[]) as Array)+(favour.get_meta("actions",[]) as Array)
		for act in ["terrify","penance","cast_out","strike_down","bless","boon","raise_up"]: _check(act in acts,"the menus lack %s" % act)
	var witnesses:=_court_ids(id)
	var before:=_bonds(pid)
	var wbefore:=_witness_bonds(witnesses)
	var result:Dictionary=modal.divine("terrify")
	_check(bool(result.get("ok",false)),"terrify failed: %s" % str(result))
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	var after:=_bonds(pid)
	var gain:=float(after.fear)-float(before.fear)
	_check(gain>0.05 and gain<=0.27,"terrify fear gain out of bounds: %.3f" % gain)
	_check(float(after.love)<float(before.love),"terrify did not cool love")
	_check(float(after.resentment)>=float(before.resentment),"terrify lowered resentment")
	for wid in witnesses:
		var wa:=_bonds(int(wid))
		var wg:=float(wa.fear)-float(wbefore[int(wid)].fear)
		_check(wg>0.0 and wg<=0.06,"witness %d fear change out of bounds after terrify: %.3f" % [int(wid),wg])
	# Graded by courage: the bravest witness shakes least.
	if witnesses.size()>=2:
		var sorted:=witnesses.duplicate()
		sorted.sort_custom(func(a:int,b:int)->bool:return float(GovernmentPeopleSystem.person_snapshot(a).get("courage",0.5))<float(GovernmentPeopleSystem.person_snapshot(b).get("courage",0.5)))
		var timid:=int(sorted[0]); var brave:=int(sorted[-1])
		_check(float(_bonds(timid).fear)-float(wbefore[timid].fear)>=float(_bonds(brave).fear)-float(wbefore[brave].fear),"witness dread is not graded by courage")
	_check(not (GovernmentPeopleSystem.person_snapshot(pid).memories as Array).is_empty() and String((GovernmentPeopleSystem.person_snapshot(pid).memories as Array)[0].get("kind",""))=="divine","terrify left no memory")
	_check(not bool(modal.divine("terrify").get("ok",true)),"terrify could be repeated in one audience")
	_check(modal.card.size.y<=modal.DESIGN_SIZE.y+1.0,"the meter and acts grew the card: %s" % modal.card.size)
	# Penance.
	before=_bonds(pid)
	_check(bool(modal.divine("penance").get("ok",false)),"penance failed")
	after=_bonds(pid)
	_check(float(after.obligation)>float(before.obligation) and float(after.fear)>float(before.fear),"penance did not raise obligation and dread")
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	_record(id,"TERRIFYING A SUMMONED OFFICIAL")
	modal.make_them_wait()
	await _frames(2)
	# Favour on a second official.
	var other:Dictionary=Hall._officials()[1]
	var oid:=int(other.person_id)
	modal=director.summon({"person_id":oid})
	id=String(modal.audience_id)
	await _wait(modal,id,1)
	witnesses=_court_ids(id)
	before=_bonds(oid)
	wbefore=_witness_bonds(witnesses)
	result=modal.divine("bless")
	_check(bool(result.get("ok",false)),"bless failed")
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	after=_bonds(oid)
	_check(float(after.love)-float(before.love)>0.05 and float(after.love)-float(before.love)<=0.13,"bless love gain out of bounds")
	_check(float(after.fear)<=float(before.fear) and float(after.resentment)<=float(before.resentment),"bless did not ease dread and resentment")
	for wid in witnesses:
		var wa2:=_bonds(int(wid))
		_check(float(wa2.love)>=float(wbefore[int(wid)].love),"a witness lost love when another was blessed")
		var proud:=float(GovernmentPeopleSystem.person_snapshot(int(wid)).get("pride",0.5))>0.7
		if proud: _check(float(wa2.resentment)>float(wbefore[int(wid)].resentment),"a proud witness felt no envy at a blessing")
	# A real boon from the stores.
	var boon:Dictionary={}
	for option in Hall.divine_options(id):
		if String(option.id)=="boon": boon=option
	var stock_before:=0.0
	var boon_result:Dictionary
	var resource:=""
	for r in Hall.RESOURCES:
		if String(boon.get("sub","")).contains(r): resource=r
	stock_before=Hall.player_stock(resource)
	before=_bonds(oid)
	boon_result=modal.divine("boon")
	_check(bool(boon_result.get("ok",false)),"boon failed: %s" % str(boon_result))
	var paid:=float((boon_result.get("terms",{}) as Dictionary).get("amount",0.0))
	_check(paid>0.0 and absf(Hall.player_stock(resource)-(stock_before-paid))<0.01,"boon did not come out of the real stores (%s %.1f -> %.1f, paid %.1f)" % [resource,stock_before,Hall.player_stock(resource),paid])
	after=_bonds(oid)
	_check(float(after.obligation)>float(before.obligation),"boon did not bind obligation")
	before=_bonds(oid)
	_check(bool(modal.divine("raise_up").get("ok",false)),"raise up failed")
	after=_bonds(oid)
	_check(float(after.respect)>float(before.respect),"raising up did not raise respect")
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	_check(GovernmentPeopleSystem.person_snapshot(oid).relationships.sovereign.has("love"),"favour did not write the love field")
	if capture: await _capture("blessed-official")
	_record(id,"BLESSING ANOTHER OFFICIAL")
	modal._close()
	await _frames(2)

func _test_strike_down()->void:
	var officials:=Hall._officials()
	var target:Dictionary=officials[officials.size()-1]
	var pid:=int(target.person_id)
	var office:=String(target.get("office_key",""))
	var legitimacy:=float(GameState.simulation_metrics.get("legitimacy",0.5))
	var modal:Control=director.summon({"person_id":pid})
	var id:=String(modal.audience_id)
	await _wait(modal,id,1)
	modal.speech_input.text="Why have you failed me?"
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	var witnesses:=_court_ids(id)
	var wbefore:=_witness_bonds(witnesses)
	var result:Dictionary=modal.divine("strike_down")
	_check(bool(result.get("ok",false)) and bool(result.get("terminal",false)),"strike down failed: %s" % str(result))
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	var dead:=GovernmentPeopleSystem.person_snapshot(pid)
	_check(String(dead.get("status",""))=="deceased","the struck-down official is not dead (%s)" % String(dead.get("status","")))
	_check(String(Hall.find(id).status)=="resolved","the audience did not end with the execution")
	_check(float(GameState.simulation_metrics.get("legitimacy",0.5))<legitimacy,"execution cost no legitimacy")
	if office!="settlement" and office!="":
		var holder:=GovernmentPeopleSystem.officeholder(office)
		_check(holder.is_empty() or int(holder.person_id)!=pid,"the dead still hold the office")
	for person in Hall._officials(): _check(int(person.person_id)!=pid,"the dead official is still at court")
	for wid in witnesses:
		var gain:=float(_bonds(int(wid)).fear)-float(wbefore[int(wid)].fear)
		_check(gain>=0.1 and gain<=0.19,"witness %d dread did not spike at the execution: %.3f" % [int(wid),gain])
		_check(float(_bonds(int(wid)).love)<float(wbefore[int(wid)].love),"witness love did not fall at the execution")
	# The dead do not speak after.
	var lines:Array=Hall.find(id).lines
	var after_decree:=false
	for line in lines:
		if String(line.get("role",""))=="narrator" and "put to death" in String(line.get("text","")): after_decree=true
		elif after_decree and int(line.get("person_id",0))==pid: _fail("the executed official spoke after death: %s" % String(line.text))
	_check(modal.find_child("ReceiptHead",true,false)!=null and "BY YOUR DECREE" in (modal.find_child("ReceiptHead",true,false) as Label).text,"execution receipt head wrong")
	if capture: await _capture("struck-down")
	_record(id,"STRIKING ONE DOWN BEFORE THE COURT")
	modal._close()
	await _frames(2)

func _test_cast_out()->void:
	var officials:=Hall._officials()
	var target:Dictionary=officials[1]
	var pid:=int(target.person_id)
	var modal:Control=director.summon({"person_id":pid})
	var id:=String(modal.audience_id)
	await _wait(modal,id,1)
	var witnesses:=_court_ids(id)
	var wbefore:=_witness_bonds(witnesses)
	var result:Dictionary=modal.divine("cast_out")
	_check(bool(result.get("ok",false)),"cast out failed: %s" % str(result))
	_check(String(GovernmentPeopleSystem.person_snapshot(pid).get("status",""))=="exiled","the cast-out official is not exiled")
	for person in Hall._officials(): _check(int(person.person_id)!=pid,"the exile is still at court")
	for wid in witnesses: _check(float(_bonds(int(wid)).fear)>float(wbefore[int(wid)].fear),"exile raised no dread in witness %d" % int(wid))
	_check(not Hall.summonable().any(func(e:Dictionary)->bool:return int((e.target as Dictionary).get("person_id",0))==pid),"the exile can still be summoned")
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	modal._close()
	await _frames(2)

func _leader(fear:float,love:Variant,resentment:float=0.0,honesty:float=0.5)->Dictionary:
	var person:Dictionary=(Hall._officials()[0] as Dictionary).duplicate(true)
	person["honesty"]=honesty; person["courage"]=0.5; person["pride"]=0.5; person["suspicion"]=0.4
	var rel:={"trust":0.55,"respect":0.55,"fear":fear,"resentment":resentment,"obligation":0.45}
	if love!=null: rel["love"]=float(love)
	person["relationships"]={"sovereign":rel}
	return person

func _test_consequences()->void:
	var calm:=_leader(0.1,null)
	var dread:=_leader(0.85,null)
	var loved:=_leader(0.1,0.9)
	var rate:=0.5
	var f_calm:float=AdvisorSystem._leader_forecast_score(calm,rate)
	var f_dread:float=AdvisorSystem._leader_forecast_score(dread,rate)
	var f_loved:float=AdvisorSystem._leader_forecast_score(loved,rate)
	_check(f_dread-f_calm>=0.08,"high dread does not overpromise measurably (%.3f vs %.3f)" % [f_dread,f_calm])
	_check(absf(f_loved-rate)<=absf(f_calm-rate)+0.0001,"love does not make a forecast straighter (%.3f vs %.3f)" % [f_loved,f_calm])
	var honest_dread:=_leader(0.85,null,0.0,0.95)
	_check(float(AdvisorSystem._leader_forecast_score(honest_dread,rate))<f_dread,"honesty does not temper frightened overpromising")
	var assessment:={"coercion":0.0,"implementation_rate":rate}
	var w_calm:float=AdvisorSystem._leader_willingness(calm,"care_rotation",assessment)
	var w_dread:float=AdvisorSystem._leader_willingness(dread,"care_rotation",assessment)
	_check(w_dread>w_calm,"dread does not raise willingness (%.3f vs %.3f)" % [w_dread,w_calm])
	_check(Divine.candor(loved)>Divine.candor(calm) and Divine.candor(calm)>Divine.candor(dread),"candor is not raised by love and lowered by dread")
	_check(String(GovernmentPeopleSystem.leader_disposition(dread).id)=="sycophantic","a terrified official is not deferential")
	_check(String(GovernmentPeopleSystem.leader_disposition(loved).id)=="principled","a loving, unafraid official is not plain-spoken")
	var proud_brave:=_leader(0.7,null); proud_brave["pride"]=0.9; proud_brave["courage"]=0.9
	_check(String(GovernmentPeopleSystem.leader_disposition(proud_brave).id)!="sycophantic","the proud and brave bent into flattery")

func _set_bonds(pid:int,values:Dictionary)->void:
	var now:=_bonds(pid)
	var deltas:={}
	for key in values: deltas[key]=float(values[key])-float(now.get(key,0.0))
	GovernmentPeopleSystem.adjust_person_bonds(pid,deltas)

func _test_flight()->void:
	var officials:=Hall._officials()
	var steady:Dictionary=officials[0]
	var uneasy:Dictionary=officials[officials.size()-1]
	var sid:=int(steady.person_id); var uid:=int(uneasy.person_id)
	_check(sid!=uid,"need two distinct officials for the flight test")
	_set_bonds(sid,{"fear":0.55,"resentment":0.2,"love":0.4})
	_set_bonds(uid,{"fear":0.9,"resentment":0.7,"love":0.2,"obligation":0.2})
	var steady_person:=GovernmentPeopleSystem.person_snapshot(sid)
	_check(Divine.flight_risk(steady_person)==0.0,"flight risk below the thresholds is not zero")
	var day:=int(GameState.elapsed_days)+1
	GameState.elapsed_days=day
	Hall.daily(day)
	_check(not Divine.warned(sid),"an official below the thresholds was marked as thinking of flight")
	_check(Divine.warned(uid),"a terrified, resentful official did not start thinking of flight")
	_check(String((GovernmentPeopleSystem.person_snapshot(uid).memories as Array)[0].get("outcome",""))=="thinks_of_flight","no memory of the first thought of flight")
	# It is telegraphed: summoned, they let it slip.
	var modal:Control=director.summon({"person_id":uid})
	var id:=String(modal.audience_id)
	await _wait(modal,id,1)
	var hints:={}
	for line in DV.generic("flight_hint"): hints[Voice.norm_line(String(line))]=true
	var hinted:=false
	for line in Hall.find(id).lines:
		if int(line.get("person_id",0))==uid and hints.has(Voice.norm_line(String(line.text))): hinted=true
	_check(hinted,"the official thinking of flight did not let it slip: %s" % str((Hall.find(id).lines as Array).map(func(l:Dictionary)->String:return String(l.text))))
	var ctx:=Hall.voice_context(id)
	_check((ctx.petitioner as Dictionary).get("regard",{}).has("thinking_of_flight"),"the live voice is not told they are thinking of flight")
	# Quiet sabotage, bounded, only once telegraphed.
	var person:=GovernmentPeopleSystem.person_snapshot(uid)
	var cut:=Divine.sabotage(person)
	_check(cut>0.0 and cut<=Divine.SABOTAGE_MAX,"no bounded sabotage from a telegraphed official: %.3f" % cut)
	var unwarned:=person.duplicate(true); unwarned["person_id"]=999999
	_check(Divine.sabotage(unwarned)==0.0,"sabotage without telegraphing")
	var with_cut:float=AdvisorSystem.execution_modifier_for_advisor(person,"Steward",["Administration"])
	var without_cut:float=AdvisorSystem.execution_modifier_for_advisor(unwarned,"Steward",["Administration"])
	_check(with_cut<without_cut or with_cut<=0.35,"sabotage does not reduce execution (%.3f vs %.3f)" % [with_cut,without_cut])
	modal.make_them_wait()
	await _frames(2)
	# Not before WARN_DAYS; then, while it holds, they may go.
	var warned_on:=day
	var fled_day:=-1
	for step in 400:
		day+=1
		GameState.elapsed_days=day
		_set_bonds(uid,{"fear":0.9,"resentment":0.7,"love":0.2,"obligation":0.2})
		Hall.daily(day)
		if String(GovernmentPeopleSystem.person_snapshot(uid).get("status",""))=="fled": fled_day=day; break
	_check(fled_day>0,"a long-telegraphed, terrified, resentful official never fled")
	_check(fled_day<0 or fled_day-warned_on>=Divine.WARN_DAYS,"flight came before it was telegraphed long enough")
	_check(String(GovernmentPeopleSystem.person_snapshot(sid).get("status",""))=="active","the steady official fled")
	var titles:Array=GameState.simulation_events.map(func(e:Dictionary)->String:return String(e.get("title","")))
	_check("Official Fled" in titles,"no event records the flight")
	for person2 in Hall._officials(): _check(int(person2.person_id)!=uid,"the fled official is still at court")

func _test_free_text()->void:
	var officials:=Hall._officials()
	var pid:=int((officials[0] as Dictionary).person_id)
	_set_bonds(pid,{"fear":0.1,"resentment":0.05})
	var modal:Control=director.summon({"person_id":pid})
	var id:=String(modal.audience_id)
	await _wait(modal,id,1)
	var before:=_bonds(pid)
	modal.speech_input.text="I will destroy you."
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	_check("terrify" in (Hall.find(id).get("divine",[]) as Array),"'I will destroy you' did not terrify")
	_check(float(_bonds(pid).fear)>float(before.fear),"free-text terror moved no dread")
	_check(terrain.decrees.is_empty() or not "destroy" in String(terrain.decrees[-1]),"terror was routed as a civic order")
	_check(Divine.intent("Tell me about the harvest.")=="","an ordinary question read as an act")
	_check(Divine.intent("Kneel before me, worm.")=="terrify","'kneel before me' did not read as terror")
	_check(Divine.intent("I bless you for your service.")=="bless","a blessing did not read as a blessing")
	_check(Divine.intent("You must atone for this.")=="penance","atonement did not read as penance")
	_check(Divine.intent("Strike them down.")=="","execution is possible by speech alone")
	modal.make_them_wait()
	await _frames(2)

func _test_live_classifier()->void:
	var officials:=Hall._officials()
	var pid:=int((officials[officials.size()-1] as Dictionary).person_id)
	var modal:Control=director.summon({"person_id":pid})
	var id:=String(modal.audience_id)
	await _wait(modal,id,1)
	var voice:Node=director.voice
	var payloads:Array=[]
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":"k","model":"mock-model","structured_output":true}
	voice.send_hook=func(aid:String,payload:Dictionary,attempt:int)->void:
		payloads.append(payload)
		var body:=JSON.stringify({"id":"m","model":"mock-model","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":JSON.stringify({"lines":[{"speaker_key":"envoy","text":"I hear the thunder in your voice and I bow my head to the floor.","aside":false}],"mood_shift":-0.2,"divine":"terrify"})}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}})
		voice._on_response.call_deferred(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),body.to_utf8_buffer(),aid,attempt)
	var before:=_bonds(pid)
	modal.speech_input.text="You have disappointed your maker for the last time."
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	await _frames(4)
	voice.send_hook=Callable(); voice.config_override={}; voice.force_offline=true
	_check(not payloads.is_empty(),"the live voice was not asked")
	if not payloads.is_empty():
		var schema:Dictionary=(payloads[0] as Dictionary).get("response_format",{}).get("json_schema",{}).get("schema",{})
		var enum_values:Array=(schema.get("properties",{}) as Dictionary).get("divine",{}).get("enum",[])
		_check("terrify" in enum_values and not "strike_down" in enum_values and not "cast_out" in enum_values,"the classifier field is not bounded to spoken acts: %s" % str(enum_values))
		var prompt:=String(((payloads[0] as Dictionary).messages as Array)[1].content)
		_check("REGARD FOR THE GOD" in prompt,"the live prompt lacks the love/dread state")
		_check("THE GOD LATELY" in prompt,"the live prompt lacks the recent acts of the god")
	_check("terrify" in (Hall.find(id).get("divine",[]) as Array),"the live classifier's terrify was not applied")
	_check(float(_bonds(pid).fear)>float(before.fear),"the classified terror moved no dread")
	modal.make_them_wait()
	await _frames(2)

func _test_envoy()->void:
	var audience:=Hall.debug_force("gift","rival_c")
	if audience.is_empty(): _fail("no envoy audience could be forced"); return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait(modal,id,1)
	var regard_before:=Hall.regard_of(id)
	_check(not regard_before.is_empty() and modal.find_child("RegardRead",true,false)!=null,"no regard shown for an envoy's people")
	var leader_trust:=float(ForeignDiplomacy.leader("rival_c").get("trust",0.0))
	var dread_before:=Divine.civ_dread("rival_c")
	modal.speech_input.text="Kneel before me, or I will destroy you and all your kin."
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	var result_dread:=Divine.civ_dread("rival_c")
	_check(result_dread>dread_before,"terrifying an envoy raised no dread in their people")
	_check(float(ForeignDiplomacy.leader("rival_c").get("trust",0.0))<leader_trust,"the engine did not read the envoy's terror as intimidation")
	_check(float(Hall.regard_of(id).dread)>float(regard_before.dread),"the envoy's people's dread meter did not rise")
	_check(Hall.divine_options(id).size()==1 and not bool(Hall.divine_options(id)[0].enabled),"an envoy could be terrified twice")
	var envoy_lines:=(Hall.find(id).lines as Array).filter(func(l:Dictionary)->bool:return String(l.get("role",""))=="envoy")
	_check(envoy_lines.size()>=2,"the envoy did not react to terror")
	if capture: await _capture("terrified-envoy")
	_record(id,"TERRIFYING A FOREIGN ENVOY")
	modal.make_them_wait()
	await _frames(2)

func _test_saves()->void:
	var state:Dictionary=ForeignDiplomacy.audiences
	_check(state.has("divine") and Hall.validate_state(state),"hall state with divine block does not validate")
	var round:Variant=JSON.parse_string(JSON.stringify(state))
	_check(Hall.validate_state(round),"hall state does not survive a JSON round trip")
	var legacy:Dictionary=(round as Dictionary).duplicate(true)
	legacy.erase("divine")
	_check(Hall.validate_state(legacy),"a legacy hall state without the divine block is rejected")
	var bad:Dictionary=(round as Dictionary).duplicate(true)
	bad["divine"]={"civ_dread":{"x":{"v":5.0,"day":1}}}
	_check(not Hall.validate_state(bad),"an out-of-range divine block validates")
	bad["divine"]={"events":[{"day":1,"action":"smite_with_lightning"}]}
	_check(not Hall.validate_state(bad),"an unknown divine act validates")
	# Person records keep love through a round trip; a legacy record reads sensibly.
	var people:Variant=JSON.parse_string(JSON.stringify(GovernmentPeopleSystem.people))
	var with_love:=0
	for p in people:
		if (p as Dictionary).get("relationships",{}).get("sovereign",{}).has("love"): with_love+=1
	_check(with_love>0,"love did not survive a round trip of person records")
	var old:Dictionary=(people[0] as Dictionary).duplicate(true)
	(old.relationships.sovereign as Dictionary).erase("love")
	var r:=Divine.regard(old)
	_check(r.has("love") and float(r.love)>=0.0 and float(r.love)<=1.0,"a legacy person without love has no reading")
	# Loading the divine state back in keeps the recent acts.
	ForeignDiplomacy.audiences=(round as Dictionary)
	_check(not Divine.events(8).is_empty(),"recent acts lost in the round trip")

# ---------------------------------------------------------------------------

func _record(id:String,label:String)->void:
	var audience:=Hall.find(id)
	var block:=PackedStringArray(["","--- %s · %s %s" % [label,String((audience.speaker as Dictionary).get("title","")),String((audience.speaker as Dictionary).get("name",""))]])
	var down:=RegEx.new(); down.compile(TALKING_DOWN)
	for line in audience.get("lines",[]):
		var text:=String(line.get("text",""))
		var who:=String(line.get("speaker",""))
		block.append("  %s%s: %s" % [who if who!="" else "(narrator)"," (aside)" if bool(line.get("aside",false)) else "",text])
		if String(line.get("role",""))in ["ruler","narrator"]: continue
		var key:=Voice.norm_line(text)
		if seen_lines.has(key): _fail("said twice: %s" % text)
		seen_lines[key]=true
		if text.split(" ",false).size()>32: _fail("line runs long: %s" % text)
		if down.search(text)!=null: _fail("someone talked down to the god: %s" % text)
	if String(audience.get("outcome",""))!="": block.append("  Outcome: %s" % String(audience.outcome))
	transcripts.append("\n".join(block))

func _capture(label:String)->void:
	await _frames(6)
	await RenderingServer.frame_post_draw
	var path:=out_dir+"fear-love-"+label+".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("FEAR_LOVE capture ",path)

func _finish()->void:
	for block in transcripts: print(block)
	if failures.is_empty():
		print("FEAR_LOVE PASS")
		get_tree().quit(0)
	else:
		print("FEAR_LOVE FAILURES: %d" % failures.size())
		get_tree().quit(1)
