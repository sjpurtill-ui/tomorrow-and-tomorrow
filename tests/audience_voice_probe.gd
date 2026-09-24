extends Node
## Headless probe for character_voice.gd + audience_voice.gd.
## Uses an in-memory stub of the AudienceHall static API so it runs without a
## generated world, and mocks HTTP by feeding fabricated bodies to the handler.

const CV:=preload("res://scripts/character_voice.gd")
const Voice:=preload("res://scripts/audience_voice.gd")

class StubHall:
	var audiences:Dictionary={}
	var courts:Dictionary={}
	var order:Array=[]   # newest first, standing in for the hall's history
	func state()->Dictionary:
		var history:Array=[]
		for id in order: history.append(audiences[id])
		return {"queue":[],"history":history}
	func find(id:String)->Dictionary: return audiences.get(id,{})
	func court(id:String)->Array: return courts.get(id,[])
	func voice_context(id:String)->Dictionary:
		var a:=find(id)
		if a.is_empty(): return {}
		var ctx:={"kind":a.kind,"origin":a.origin,"terms":a.terms,"news":a.news,"petition":a.petition,"player_settlement":"Ashford",
			"food_situation":"food is adequate but not generous","days_until_leaving":17}
		if a.origin=="foreign":
			ctx["civ"]={"name":a.civ_name,"opinion":"wary but civil","border":"watchful"}
			ctx["leader"]={"name":"Queen Ottavie","temperament":"Proud guardian","goals":["Keep our homeland independent"]}
		return ctx
	func append_line(id:String,line:Dictionary)->void: (find(id).lines as Array).append(line)
	func apply_mood(id:String,shift:float)->void:
		var a:=find(id)
		a.mood=clampf(float(a.mood)+clampf(shift,-0.25,0.25),-1.0,1.0)

var failures:Array[String]=[]
var ready_ids:Array[String]=[]
var stub:=StubHall.new()
var voice:Node
var sent_payloads:Array[Dictionary]=[]
var mock_plan:Array=[]   # queue of [result, code, body_string]

func _expect(ok:bool,message:String)->void:
	if not ok: failures.append(message)

func _person(pid:int,person_name:String,title:String,traits:Array,extra:Dictionary={})->Dictionary:
	var p:={"person_id":pid,"name":person_name,"office_title":title,"office_key":title,"traits":traits,"background":"Store and harvest keeper",
		"personality":{"openness":0.5,"discipline":0.5,"empathy":0.5,"assertiveness":0.5,"risk_tolerance":0.5},
		"relationships":{"sovereign":{"trust":0.55,"respect":0.5,"fear":0.1,"resentment":0.0,"obligation":0.5}},
		"honesty":0.6,"courage":0.6,"pride":0.5,"suspicion":0.4}
	for k in extra: p[k]=extra[k]
	return p

func _audience(id:String,kind:String,origin:String="foreign")->Dictionary:
	var a:={"id":id,"origin":origin,"kind":kind,"civ_id":"civ_%s" % kind,"civ_name":"the Velmari","speaker":{"name":"Sabeth Orrow","title":"Voice of Queen Ottavie","person_id":0,"role":"envoy"},
		"arrived_day":10,"expires_day":30,"status":"waiting","terms":{},"news":{},"petition":{},"lines":[],"outcome":"","option_id":"","mood":0.0}
	if kind in ["gift","request","threat"]: a.terms={"resource":"Food","amount":40.0}
	if kind=="news": a.news={"subject_civ_id":"civ_x","subject_civ_name":"the Harrowfolk","fact_kind":"war","fact":"The Harrowfolk and the Dunmere are at war."}
	if origin=="court":
		a.civ_id=""; a.civ_name=""
		a.speaker={"name":"Tamsin Wolde","title":"Quartermaster","person_id":7,"role":"official"}
	return a

func _court()->Array:
	return [
		_person(11,"Orrin Vale","Marshal",["Bold","Severe"],{"suspicion":0.8}),
		_person(12,"Ysra Fenn","Steward",["Warm","Diplomatic"],{"personality":{"openness":0.5,"discipline":0.5,"empathy":0.8,"assertiveness":0.4,"risk_tolerance":0.5}}),
		_person(13,"Callum Brisk","Scholar",["Curious","Humble"],{"courage":0.3,"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.3,"resentment":0.0,"obligation":0.5}}}),
	]

func _on_ready_line(id:String)->void: ready_ids.append(id)

func _ready()->void:
	GameState.world_seed=424242
	voice=Voice.new()
	voice.hall=stub
	voice.force_offline=true
	add_child(voice)
	voice.lines_ready.connect(_on_ready_line)
	_test_personas()
	await _test_offline_scenes()
	_test_validator()
	await _test_mocked_api()
	await _test_real_hall_if_present()
	if failures.is_empty():
		print("AUDIENCE_VOICE PASS")
		get_tree().quit(0)
	else:
		for f in failures: push_error("AUDIENCE_VOICE "+f)
		print("AUDIENCE_VOICE FAIL (%d)" % failures.size())
		get_tree().quit(1)

# ---------------------------------------------------------------------------

func _test_personas()->void:
	var a:=CV.for_person(_court()[0])
	var b:=CV.for_person(_court()[0])
	_expect(JSON.stringify(a)==JSON.stringify(b),"for_person is not deterministic")
	_expect(String(a.stance)=="cantankerous","suspicious Severe marshal should read cantankerous, got %s" % a.stance)
	for key in ["key","name","voice","dialect","tics","want","fear","quirk","secret","temper","sample"]:
		_expect(a.has(key),"persona missing %s" % key)
	var e1:=CV.for_envoy("civ_a","aud_1"); var e2:=CV.for_envoy("civ_a","aud_1")
	_expect(JSON.stringify(e1)==JSON.stringify(e2),"for_envoy is not deterministic")
	var dialects:={}
	var voices:={}
	for i in 16:
		var e:=CV.for_envoy("civ_%d" % i,"aud_%d" % i)
		dialects[e.dialect_id]=true; voices[e.voice]=true
		_expect(String(e.dialect_id)==String(CV.for_civilization("civ_%d" % i).dialect_id),"envoy does not share their people's dialect")
	_expect(dialects.size()>=6,"too little dialect variety (%d)" % dialects.size())
	_expect(voices.size()>=5,"too little voice variety")
	var scout:=CV.for_person(_person(20,"Wren Hollis","Chief Scout",["Bold","Curious"],{"office_key":"ChiefScout"}))
	_expect("woodsmoke" in String(scout.quirk),"Chief Scout office flavour missing")
	print("--- SAMPLE PERSONAS ---")
	var samples:Array=[CV.for_envoy("civ_1","aud_1"),CV.for_envoy("civ_2","aud_9"),CV.for_envoy("civ_5","aud_3")]
	for p in _court(): samples.append(CV.for_person(p))
	for p in samples.slice(0,6):
		print("* "+CV.brief(p))
		print("    sample: "+String(p.sample))

func _run_scene(id:String,kind:String,origin:String,speeches:Array,option_id:String,reaction:String,topic:String="food")->Array:
	var a:=_audience(id,kind,origin)
	if kind=="petition":
		var summaries:={"food":"Food stores would last about 9 days; people are counting portions.","grievance":"Tamsin Wolde feels their counsel has been ignored.","ambition":"Tamsin Wolde wants the workshops enlarged and tools made in earnest."}
		var decrees:={"food":"Send gatherers to find food","grievance":"","ambition":"Expand workshops and make tools"}
		a.petition={"topic":topic,"summary":summaries[topic],"suggested_decree":decrees[topic]}
	if kind=="report":
		a.speaker={"name":"Wren Hollis","title":"Chief Scout","person_id":20,"role":"official"}
		a["report"]={"facts":[{"key":"population","label":"≈340 people","text":"About 340 people live there.","confidence":0.7,"value":340},{"key":"walls","label":"stone walls","text":"Stone walls on the east side.","confidence":0.9},{"key":"makers","label":"kilns","text":"Smoke from three kilns.","confidence":0.8}],"subject_civ_id":"civ_x","subject_name":"the Harrowfolk","source":"scouts","observed_day":6}
	stub.audiences[id]=a
	stub.order.push_front(id)
	stub.courts[id]=_court()
	ready_ids.clear()
	voice.open_scene(id)
	var after_open:=(a.lines as Array).size()
	_expect(after_open>=3,"%s open produced only %d lines" % [id,after_open])
	_expect(String(a.lines[0].speaker)==String(a.speaker.name),"%s open did not start with the visitor" % id)
	for text in speeches:
		voice.player_speaks(id,String(text))
	a.option_id=option_id
	voice.closing(id,{"ok":true,"outcome":"Recorded.","reaction":reaction,"option_id":option_id})
	await get_tree().process_frame
	_expect(ready_ids.size()>=2+speeches.size(),"%s lines_ready not emitted per call (%d)" % [id,ready_ids.size()])
	var ruler_lines:=0
	for line in a.lines:
		var t:=String(line.text)
		_expect(not t.is_empty(),"%s blank line" % id)
		_expect(not ("{" in t or "}" in t),"%s unresolved token: %s" % [id,t])
		for key in ["speaker","role","person_id","civ_id","text","day","aside"]: _expect(line.has(key),"%s line missing %s" % [id,key])
		if String(line.role)=="ruler": ruler_lines+=1
	_expect(ruler_lines==speeches.size(),"%s ruler lines not echoed exactly once" % id)
	# Each speaker's pet phrase opens at most one line per scene and never trails one.
	var sc:Dictionary=voice.scene(id)
	var members:Array=[sc.envoy]+sc.officials
	for member in members:
		for tic in member.persona.get("tics",[]):
			var uses:=0
			for line in a.lines:
				if String(line.speaker)==String(member.name) and String(tic) in String(line.text): uses+=1
				_expect(not String(line.text).ends_with(String(tic)),"%s tic trails a line: %s" % [id,line.text])
			_expect(uses<=1,"%s: %s used pet phrase '%s' %d times" % [id,member.name,tic,uses])
	return a.lines

func _test_offline_scenes()->void:
	var all:Array=[]
	all.append(await _run_scene("aud_g","gift","foreign",["Thank you, friend, this is generous."],"accept_return","delighted"))
	all.append(await _run_scene("aud_r","request","foreign",["Why should we feed you?"],"grant_half","neutral"))
	all.append(await _run_scene("aud_t","threat","foreign",["Never. Get out of my hall, you coward."],"defy","furious"))
	all.append(await _run_scene("aud_n","news","foreign",[],"reward","pleased"))
	all.append(await _run_scene("aud_p","petition","court",["Tell me more."],"decree","pleased","food"))
	all.append(await _run_scene("aud_q","petition","court",[],"rebuke","offended","grievance"))
	all.append(await _run_scene("aud_a","petition","court",[],"promise","neutral","ambition"))
	all.append(await _run_scene("aud_s","report","court",[],"reward","pleased"))
	var distinct:={}
	var total:=0
	for lines in all:
		for line in lines:
			total+=1; distinct[String(line.text)]=true
	_expect(float(distinct.size())/float(total)>0.85,"offline lines repeat too often (%d/%d distinct)" % [distinct.size(),total])
	# A second audience of the same kind must not replay the first one word for word.
	var again:=await _run_scene("aud_g2","gift","foreign",[],"accept","pleased")
	var same:=0
	for i in mini(3,again.size()):
		if String(again[i].text)==String(all[0][i].text): same+=1
	_expect(same<2,"a second gift audience replayed the first")
	# Five audiences in a row: no official should keep opening the same way.
	var leads_by_speaker:Dictionary={}
	var streak_lines:Array=[]
	for i in 5:
		var lines:Array=await _run_scene("aud_streak_%d" % i,"request","foreign",["Why should we?"],"refuse","offended")
		streak_lines.append_array(lines)
		var seen_here:Dictionary={}
		for line in lines:
			if String(line.role)!="official": continue
			var key:=String(line.speaker)+"|"+String(line.text).get_slice(" ",0)+" "+String(line.text).get_slice(" ",1)
			if seen_here.has(key): continue
			seen_here[key]=true
			leads_by_speaker[key]=int(leads_by_speaker.get(key,0))+1
	var repeats:Array=[]
	for key in leads_by_speaker:
		if int(leads_by_speaker[key])>2: repeats.append(key)
	_expect(repeats.is_empty(),"officials repeat the same opening across recent audiences: %s" % JSON.stringify(repeats))
	print("--- STREAK SAMPLE ---")
	for line in streak_lines.slice(streak_lines.size()-8):
		print("  %s%s: %s" % [String(line.speaker)," (aside)" if bool(line.aside) else "",String(line.text)])
	print("--- SAMPLE OFFLINE SCENES ---")
	for lines in all:
		for line in lines:
			print("  %s%s [%s]: %s" % [String(line.speaker)," (aside)" if bool(line.aside) else "",String(line.role),String(line.text)])
		print("  ...")
	_expect(float(stub.find("aud_g").mood)>0.0 and float(stub.find("aud_t").mood)<0.0,"offline speech did not nudge room mood")

func _test_validator()->void:
	var a:=_audience("aud_v","request")
	stub.audiences["aud_v"]=a; stub.courts["aud_v"]=_court()
	var s:Dictionary=voice.scene("aud_v")
	var keys:Array=voice.cast_keys(s)
	_expect(keys.has("envoy") and keys.has("official_11"),"cast keys missing")
	var raw:=[
		{"speaker_key":"envoy","text":"Sabeth Orrow: Forty sacks? No. 40 food, as I said.","aside":false},
		{"speaker_key":"ghost_king","text":"I appear from nowhere!","aside":false},
		{"speaker_key":"official_11","text":"This game has a terrible button.","aside":false},
		{"speaker_key":"official_12","text":"They'll want 300 more by spring, mark me.","aside":false},
		{"speaker_key":"official_13","text":"As an AI I cannot say.","aside":true},
		{"speaker_key":"official_12","text":"Half would be 20, and half is a fine word.","aside":true},
		{"speaker_key":"official_11","text":"Our watch is systematic, boss, and our system of ditches is better still.","aside":false},
		"not a dict",
	]
	var out:Array=voice.validate_lines(raw,s,"speak")
	_expect(out.size()==3,"validator kept %d lines, expected 3: %s" % [out.size(),JSON.stringify(out)])
	if out.size()==2:
		_expect(String(out[0].text).begins_with("Forty sacks"),"speaker-name prefix not stripped")
		_expect(bool(out[1].aside),"aside flag lost")

func _mock_send(id:String,payload:Dictionary,attempt:int)->void:
	sent_payloads.append(payload)
	var step:Array=mock_plan.pop_front() if not mock_plan.is_empty() else [HTTPRequest.RESULT_CANT_CONNECT,0,""]
	voice._on_response.call_deferred(int(step[0]),int(step[1]),PackedStringArray(),String(step[2]).to_utf8_buffer(),id,attempt)

func _envelope(content:Dictionary)->String:
	return JSON.stringify({"id":"mock","choices":[{"message":{"role":"assistant","content":JSON.stringify(content)}}]})

func _test_mocked_api()->void:
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":"mock-key","model":"mock-model","structured_output":true}
	voice.send_hook=_mock_send
	# 1) Strict schema success; model puts an official first and invents a speaker.
	var a:=_audience("aud_m","threat")
	stub.audiences["aud_m"]=a; stub.courts["aud_m"]=_court()
	mock_plan=[[HTTPRequest.RESULT_SUCCESS,200,_envelope({"lines":[
		{"speaker_key":"official_11","text":"Pay? I'd sooner eat my own boots, and they're terrible boots.","aside":false},
		{"speaker_key":"envoy","text":"Hooves of the grey mare! Forty food, hearth-holder. Queen Ottavie waits.","aside":false},
		{"speaker_key":"stranger","text":"Who let me in?","aside":false},
		{"speaker_key":"official_12","text":"Breathe, Orrin. Everyone breathe.","aside":true}],"mood_shift":-0.4})]]
	sent_payloads.clear()
	voice.open_scene("aud_m")
	_expect(voice.busy("aud_m"),"busy() false during a live request")
	for i in 10: await get_tree().process_frame
	_expect(not voice.busy("aud_m"),"busy() stuck after response")
	var lines:Array=a.lines
	_expect(lines.size()==3,"mock success appended %d lines, expected 3" % lines.size())
	if lines.size()==3:
		_expect(String(lines[0].role)=="envoy","visitor was not moved to speak first")
		_expect(bool(lines[2].aside),"aside lost from API line")
	_expect(is_equal_approx(float(a.mood),0.0),"opening should not shift mood")
	if not sent_payloads.is_empty():
		var p:Dictionary=sent_payloads[0]
		_expect(not p.has("temperature"),"payload sends temperature")
		_expect(p.has("response_format") and p.max_completion_tokens>0 and String(p.model)=="mock-model","payload shape wrong")
		var enum_keys:Array=p.response_format.json_schema.schema.properties.lines.items.properties.speaker_key.enum
		_expect(enum_keys.has("envoy") and enum_keys.has("official_13") and enum_keys.size()==4,"speaker_key enum wrong")
		var user:String=p.messages[1].content
		_expect("40 Food" in user or "40 food" in user,"terms missing from prompt")
		_expect("Orrin Vale" in user and "Sabeth Orrow" in user,"cast missing from prompt")
		print("--- EXACT PROMPT (threat open) ---")
		print("[system]\n"+String(p.messages[0].content))
		print("[user]\n"+user)
	# 2) Speech with 400 on strict schema -> retries without response_format, then succeeds.
	mock_plan=[[HTTPRequest.RESULT_SUCCESS,400,"{\"error\":\"response_format unsupported\"}"],
		[HTTPRequest.RESULT_SUCCESS,200,_envelope({"lines":[{"speaker_key":"envoy","text":"Ha! Bold words from a small hall. Bold, bold.","aside":false}],"mood_shift":-0.1})]]
	sent_payloads.clear()
	voice.player_speaks("aud_m","We will not pay a single sack.")
	for i in 10: await get_tree().process_frame
	_expect(sent_payloads.size()==2 and sent_payloads[0].has("response_format") and not sent_payloads[1].has("response_format"),"structured-output downgrade retry missing")
	_expect(String(a.lines[-1].text).begins_with("Ha! Bold"),"downgraded reply not appended")
	_expect(float(a.mood)<0.0,"mood_shift not applied")
	# 3) Total failure -> retry once, then vivid offline fallback, never blank.
	mock_plan=[[HTTPRequest.RESULT_SUCCESS,500,"oops"],[HTTPRequest.RESULT_SUCCESS,200,_envelope({"lines":[{"speaker_key":"stranger","text":"nope","aside":false}],"mood_shift":0})]]
	sent_payloads.clear()
	var before:=(a.lines as Array).size()
	a.option_id="defy"
	voice.closing("aud_m",{"ok":true,"outcome":"You refuse the tribute.","reaction":"furious","option_id":"defy"})
	for i in 10: await get_tree().process_frame
	_expect(sent_payloads.size()==2,"failure path did not retry exactly once (%d sends)" % sent_payloads.size())
	_expect((a.lines as Array).size()>before,"failure left the scene blank")
	_expect(voice.last_problem.has("aud_m"),"failure reason not recorded")
	print("--- FALLBACK CLOSING AFTER API FAILURE ---")
	for line in (a.lines as Array).slice(before): print("  %s: %s" % [line.speaker,line.text])
	voice.send_hook=Callable()
	voice.config_override={}
	voice.force_offline=true

func _test_real_hall_if_present()->void:
	# Smoke-test against Worker A's real engine when it exists: inject an audience
	# straight into its queue (no world generation needed) and run offline lines.
	if not ResourceLoader.exists("res://scripts/audience_hall.gd"): return
	var Hall:=load("res://scripts/audience_hall.gd")
	if Hall==null or not Hall.has_method("state"): return
	var real:=Voice.new(); real.force_offline=true; add_child(real)
	var st:Dictionary=Hall.state()
	var a:=_audience("aud_real","petition","court")
	a.petition={"topic":"housing","summary":"About 12 people have no proper shelter.","suggested_decree":"Build shelters"}
	(st.queue as Array).append(a)
	real.open_scene("aud_real")
	_expect(not (Hall.find("aud_real").lines as Array).is_empty(),"real hall: no lines appended")
	(st.queue as Array).erase(a)
	real.queue_free()
