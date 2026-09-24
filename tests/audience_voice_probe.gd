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
	_test_variety_across_audiences()
	_test_indicator()
	_test_era_prehistoric()
	_test_voice_models()
	_test_situations()
	_test_house_rules()
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
	voice._mem_state={}
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
	var out:Array=voice.validate_lines(raw,s,"open")
	_expect(out.size()==3,"validator kept %d lines, expected 3: %s" % [out.size(),JSON.stringify(out)])
	if out.size()==2:
		_expect(String(out[0].text).begins_with("Forty sacks"),"speaker-name prefix not stripped")
		_expect(bool(out[1].aside),"aside flag lost")

func _mock_send(id:String,payload:Dictionary,attempt:int)->void:
	sent_payloads.append(payload)
	var step:Array=mock_plan.pop_front() if not mock_plan.is_empty() else [HTTPRequest.RESULT_CANT_CONNECT,0,""]
	voice._on_response.call_deferred(int(step[0]),int(step[1]),PackedStringArray(),String(step[2]).to_utf8_buffer(),id,attempt)

func _envelope(content:Dictionary)->String:
	return JSON.stringify({"id":"mock","model":"mock-model","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":JSON.stringify(content)}}],
		"usage":{"prompt_tokens":100,"completion_tokens":50,"total_tokens":150,"completion_tokens_details":{"reasoning_tokens":20}}})

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
	# 4) Receipts: every HTTP attempt is recorded with its cost and fate.
	var accepted_rows:=0
	var failed_http:=false
	for row in voice.usage:
		if bool(row.accepted) and int(row.http)==200 and int(row.total_tokens)==150 and int(row.prompt_tokens)==100 and int(row.reasoning_tokens)==20: accepted_rows+=1
		if int(row.http)==500 and not bool(row.accepted) and not String(row.reason).is_empty(): failed_http=true
	_expect(accepted_rows>=2,"mocked successes not receipted with usage (%d)" % accepted_rows)
	_expect(failed_http,"mocked HTTP 500 not receipted with a reason")
	var last_row:Dictionary=voice.usage[-1]
	_expect(bool(last_row.fallback) and not bool(last_row.accepted) and "validation" in String(last_row.reason),"final failed attempt not marked as fallback: %s" % JSON.stringify(last_row))
	_expect(int(voice.totals.calls)==5 and int(voice.totals.accepted)==2 and int(voice.totals.total_tokens)==450,"totals wrong: %s" % JSON.stringify(voice.totals))
	var mid:Dictionary=voice.status()
	_expect(String(mid.label).begins_with("Live voice · mock-model") and "last line offline" in String(mid.label),"indicator should admit the last live reply fell back: %s" % mid.label)
	_expect("5 live calls" in String(mid.tooltip) and "450 total" in String(mid.tooltip),"tooltip lacks session calls/tokens: %s" % mid.tooltip)
	# 5) A farewell after a silent audience costs nothing.
	var quiet:=_audience("aud_quiet","gift")
	stub.audiences["aud_quiet"]=quiet; stub.courts["aud_quiet"]=_court()
	mock_plan=[[HTTPRequest.RESULT_SUCCESS,200,_envelope({"lines":[{"speaker_key":"envoy","text":"Greetings and more greetings, hearth-holder.","aside":false}],"mood_shift":0})]]
	voice.open_scene("aud_quiet")
	for i in 6: await get_tree().process_frame
	sent_payloads.clear()
	quiet.option_id="accept"
	voice.closing("aud_quiet",{"ok":true,"outcome":"You accepted 40 Food.","reaction":"pleased","option_id":"accept"})
	for i in 4: await get_tree().process_frame
	_expect(sent_payloads.is_empty(),"closing after a silent audience still called the model")
	_expect(String(voice.usage[-1].reason).begins_with("closing kept offline") and int(voice.usage[-1].http)==0,"silent closing not receipted as offline")
	_expect(not (quiet.lines as Array).is_empty() and String(quiet.lines[-1].text).length()>0,"silent closing left no farewell")
	voice.send_hook=Callable()
	voice.config_override={}
	voice.force_offline=true

func _resolve_stub(a:Dictionary,option_id:String,outcome:String)->void:
	a.option_id=option_id; a.status="resolved"; a.outcome=outcome

func _run_series(prefix:String,kind:String,origin:String,option_id:String,outcome:String)->void:
	## Ten audiences in a row from the same speaker, each answered the same way.
	var series:=StubHall.new()
	voice.hall=series; voice._used.clear(); voice._mem_state={}   # a fresh reign
	var by_speaker:Dictionary={}
	var openings:Array[String]=[]
	var remembered:=0
	for i in 10:
		GameState.elapsed_days=100+i*25
		var id:="%s_%d" % [prefix,i]
		var a:=_audience(id,kind,origin)
		a.arrived_day=int(GameState.elapsed_days)
		if kind=="petition": a.petition={"topic":"ambition","summary":"Tamsin Wolde wants a public council where the people can be heard.","suggested_decree":"Hold a public council to hear the people"}
		series.audiences[id]=a; series.order.push_front(id); series.courts[id]=_court()
		voice.open_scene(id)
		voice.player_speaks(id,"Go on.")
		voice.closing(id,{"ok":true,"outcome":outcome,"reaction":"neutral","option_id":option_id})
		_resolve_stub(a,option_id,outcome)
		_expect(not (a.lines as Array).is_empty() and String(a.lines[0].speaker)==String(a.speaker.name),"%s: visitor did not open" % id)
		if (a.lines as Array).is_empty(): continue
		openings.append(String(a.lines[0].text))
		var saw_history:=false
		for line in a.lines:
			if String(line.role)=="ruler": continue
			var key:=String(line.speaker)
			var said:Dictionary=by_speaker.get(key,{})
			var text:=String(line.text)
			_expect(not said.has(text),"%s: %s repeated a line from %s: %s" % [id,key,String(said.get(text,"")),text])
			said[text]=id; by_speaker[key]=said
			if voice.remembered.get(id,"")==text: saw_history=true
		if i==0: _expect(not saw_history,"%s: first-ever audience claimed a history" % id)
		elif saw_history: remembered+=1
		if i==3:
			print("--- %s: FOURTH AUDIENCE WITH THE SAME VISITOR ---" % prefix)
			for line in a.lines: print("  %s%s: %s" % [String(line.speaker)," (aside)" if bool(line.aside) else "",String(line.text)])
	var distinct:={}
	var leads:={}
	for text in openings:
		distinct[text]=true
		leads[" ".join(text.to_lower().split(" ").slice(0,3))]=true
	_expect(distinct.size()==openings.size(),"%s: openings repeat (%d distinct of %d)" % [prefix,distinct.size(),openings.size()])
	_expect(leads.size()>=7,"%s: openings start the same way too often (%d distinct leads)" % [prefix,leads.size()])
	_expect(remembered>=7,"%s: speaker referred to past audiences only %d of 9 times" % [prefix,remembered])
	print("%s: %d openings, %d distinct leads, history referenced in %d/9" % [prefix,openings.size(),leads.size(),remembered])
	voice.hall=stub; voice._used.clear()

func _test_variety_across_audiences()->void:
	voice.force_offline=true
	_run_series("series_court","petition","court","promise","You promised Tamsin Wolde the matter of a proposal of their own would be considered. No order has been given.")
	_run_series("series_civ","gift","foreign","accept","You accepted 40 Food from the Velmari.")
	# The live prompt carries the history and a do-not-repeat list.
	var series:=StubHall.new()
	voice.hall=series; voice._used.clear()
	var old:=_audience("aud_past","petition","court")
	old.petition={"topic":"ambition","summary":"x","suggested_decree":"Hold a public council to hear the people"}
	old.lines=[{"speaker":"Tamsin Wolde","role":"official","person_id":7,"civ_id":"player","text":"A word aired costs less than a grievance left to breed.","day":10,"aside":false}]
	_resolve_stub(old,"promise","You promised Tamsin Wolde the matter would be considered.")
	series.audiences["aud_past"]=old; series.order.push_front("aud_past")
	var now:=_audience("aud_now","petition","court")
	now.petition=old.petition.duplicate()
	series.audiences["aud_now"]=now; series.courts["aud_now"]=_court()
	GameState.elapsed_days=90
	var prompt:String=voice.build_prompt(voice.scene("aud_now"),"open",{})
	_expect("BEFORE TODAY" in prompt and "You promised Tamsin Wolde the matter would be considered." in prompt,"live prompt lacks the speaker's history")
	_expect("SAID IN RECENT AUDIENCES" in prompt and "grievance left to breed" in prompt,"live prompt lacks the do-not-repeat list")
	# The hall's own ledger rows (history_with_speaker) are understood too.
	var entry:Dictionary=voice._history_entry({"day":40,"days_ago":50,"kind":"petition","ask":"ambition:Hold a public council to hear the people","answer":"promise","outcome":"Promised."},{})
	_expect(String(entry.decree)=="Hold a public council to hear the people" and String(entry.option_id)=="promise" and String(entry.topic)=="ambition","ledger history row not normalized: %s" % JSON.stringify(entry))
	voice.hall=stub; voice._used.clear()

func _test_indicator()->void:
	var probe_voice:=Voice.new(); probe_voice.hall=stub; add_child(probe_voice)
	probe_voice.force_offline=true
	_expect(String(probe_voice.status().label)=="Offline voice — switched to offline voices","forced offline label wrong: %s" % probe_voice.status().label)
	probe_voice.force_offline=false
	var was:=bool(GameState.civic_api_enabled)
	GameState.civic_api_enabled=false
	var st:Dictionary=probe_voice.status()
	_expect(not bool(st.live) and String(st.label)=="Offline voice — AI is switched off","switched-off label wrong: %s" % st.label)
	_expect("0 live calls" in String(st.tooltip) and "never cost" in String(st.tooltip),"offline tooltip wrong: %s" % st.tooltip)
	GameState.civic_api_enabled=was
	probe_voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":"k","model":"mock-model","structured_output":true}
	_expect(String(probe_voice.status().label)=="Live voice · mock-model","live label wrong: %s" % probe_voice.status().label)
	probe_voice.queue_free()

# ---------------------------------------------------------------------------
# Era, voice models and situations
# ---------------------------------------------------------------------------

const PERSONA_FIELDS:=["name","title","address","oath","proverb","quirk","secret","want","sample","dialect","fear"]

func _all_gate_ids()->Array:
	var ids:Array=[]
	for tag in CV.ERA_GATES: ids.append_array(CV.ERA_GATES[tag].ids)
	return ids

func _era_audience(id:String,kind:String,variant:int)->Dictionary:
	var origin:="court" if kind=="petition" else "foreign"
	var a:=_audience(id,kind,origin)
	a.civ_id="civ_era_%d" % (variant%5)
	if kind=="petition":
		a.civ_id=""
		var topics:=["food","health","housing","security","grievance","ambition","introduction","follow_up","war"]
		var topic:String=topics[variant%topics.size()]
		var decrees:={"food":"Send gatherers to find food","health":"Organize healers to care for the sick","housing":"Build shelters","security":"Raise a watch and post guards","ambition":"Hold a public council to hear the people"}
		a.petition={"topic":topic,"summary":"About 9 days of stores remain; about 12 people have no shelter.","suggested_decree":String(decrees.get(topic,""))}
		a.speaker={"name":"Tamsin Wolde","title":"Quartermaster","person_id":7+(variant%3),"role":"official"}
	if kind=="proposal":
		var types:=["accord_offer","protection_pact","peace_feeler","recruitment_protest","trade_offer","war_support"]
		var sit_type:String=types[variant%types.size()]
		a["situation"]={"type":sit_type,"headline":"proposes an understanding","summary":"The Velmari propose that neither people attack the other and that the frontier calm.",
			"occasion":{"type":"relation_warm","text":"the Velmari have grown warm toward your people","day":10,"crisis":false}}
	elif variant%3==0:
		a["situation"]={"type":"x","headline":"","summary":"","occasion":{"type":"ambient","text":"a long silence between your peoples","day":10,"crisis":false}}
	return a

func _test_era_prehistoric()->void:
	var founding:Array=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	CV.knowledge_override["player"]=founding
	var series:=StubHall.new()
	voice.hall=series; voice._used.clear(); voice.force_offline=true
	var kinds:=["gift","request","threat","news","petition","petition","proposal","proposal","report","petition"]
	var hits:Array=[]
	var samples:Array[String]=[]
	var total:=0
	for i in 50:
		var kind:String=kinds[i%kinds.size()]
		var id:="era_%d" % i
		var a:=_era_audience(id,kind,i)
		if kind=="report":
			a.speaker={"name":"Wren Hollis","title":"Chief Scout","person_id":20,"role":"official"}
			a["report"]={"facts":[{"key":"population","label":"≈340 people","text":"About 340 people live there.","confidence":0.7,"value":340}],"subject_civ_id":"civ_x","subject_name":"the Harrowfolk","source":"scouts","observed_day":6}
		series.audiences[id]=a; series.order.push_front(id); series.courts[id]=_court()
		GameState.elapsed_days=20+i*9
		voice.open_scene(id)
		voice.player_speaks(id,["Why should I trust you?","Thank you, friend.","Never. Get out.","Go on."][i%4])
		var option:String={"gift":"accept","request":"grant_half","threat":"defy","news":"thank","petition":"promise","proposal":"decline","report":"reward"}[kind]
		voice.closing(id,{"ok":true,"outcome":"Recorded.","reaction":["pleased","neutral","offended"][i%3],"option_id":option})
		a.status="resolved"; a.option_id=option
		for line in a.lines:
			if String(line.role)=="ruler": continue
			total+=1
			var found:=CV.lexicon_hits(String(line.text),[])
			if not found.is_empty(): hits.append("%s %s: %s %s" % [id,String(line.speaker),String(line.text),JSON.stringify(found)])
			_expect(CV.imitation_ok(String(line.text)),"%s quotes or names a source: %s" % [id,line.text])
			if samples.size()<10 and i%5==1 and String(line.text).length()>40: samples.append("%s: %s" % [String(line.speaker),String(line.text)])
	_expect(hits.is_empty(),"prehistoric anachronisms (%d of %d lines): %s" % [hits.size(),total,JSON.stringify(hits.slice(0,6))])
	# Personas are era-clean too, for every people and every official.
	var persona_hits:Array=[]
	for i in 24:
		var people:Array=[CV.for_envoy("civ_era_%d" % i,"aud_p%d" % i),CV.for_foreign_leader("civ_era_%d" % i),CV.for_person(_person(100+i,"Test Person","Steward",["Bold"]))]
		for p in people:
			for field in PERSONA_FIELDS:
				var found:=CV.lexicon_hits(String(p.get(field,"")),[])
				if not found.is_empty(): persona_hits.append("%s.%s=%s" % [String(p.name),field,p.get(field,"")])
			for tic in p.get("tics",[]):
				if not CV.lexicon_hits(String(tic),[]).is_empty(): persona_hits.append("%s tic %s" % [String(p.name),tic])
	for d in CV.DIALECTS:
		var resolved:=CV.dialect(String(d.id),[])
		for field in ["guide","label","open","address","oath","proverb","first","last"]:
			if not CV.lexicon_hits(JSON.stringify(resolved[field]),[]).is_empty(): persona_hits.append("%s.%s" % [d.id,field])
		for v in (resolved.subs as Dictionary).values():
			if not CV.lexicon_hits(String(v),[]).is_empty(): persona_hits.append("%s sub %s" % [d.id,v])
	_expect(persona_hits.is_empty(),"prehistoric personas carry anachronisms: %s" % JSON.stringify(persona_hits.slice(0,8)))
	print("--- PREHISTORIC SAMPLE LINES (%d lines scanned, %d gated hits) ---" % [total,hits.size()])
	for line in samples: print("  "+line)
	voice.hall=stub; voice._used.clear()
	# A later world permits what it has discovered.
	var later:=_all_gate_ids()
	CV.knowledge_override["player"]=later
	var tags:=CV.era_tags("player")
	_expect(tags.size()==CV.ERA_GATES.size() and CV.era_tier(tags)==3,"later era not recognised: %s" % JSON.stringify(tags))
	_expect(CV.permits("A cask of beer, a bronze bell and a written ledger.",tags),"later era still forbids its own inventions")
	_expect("Anvils and ashes!" in (CV.dialect("forge_gruff",tags).oath as Array) and String(CV.dialect("forge_gruff",tags).label)=="Gruff forge-folk","later era does not restore metal-age dialect")
	_expect(String(CV.dialect("forge_gruff",[]).label)=="Gruff flint-knapper folk","early forge dialect not era-translated")
	var tier_now:=int(CV.for_person(_court()[0]).era_tier)
	_expect(tier_now==3,"persona not re-derived for the later era")
	CV.knowledge_override["player"]=founding
	_expect(int(CV.for_person(_court()[0]).era_tier)==0,"persona tier did not follow the world back")
	CV.knowledge_override.erase("player")

func _model_person(pid:int,person_name:String,title:String,traits:Array,axes:Dictionary,extra:Dictionary={})->Dictionary:
	var p:=_person(pid,person_name,title,traits,extra)
	var personality:Dictionary=(p.personality as Dictionary).duplicate()
	for k in axes: personality[k]=axes[k]
	p.personality=personality
	return p

func _test_voice_models()->void:
	CV.knowledge_override["player"]=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	var court:Array=[
		_model_person(31,"Orrin Vale","Marshal",["Bold","Severe"],{"assertiveness":0.9,"risk_tolerance":0.85,"empathy":0.2},{"pride":0.8}),
		_model_person(32,"Ysra Fenn","Steward",["Warm","Diplomatic"],{"empathy":0.85,"openness":0.6}),
		_model_person(33,"Callum Brisk","Scholar",["Curious","Skeptical"],{"openness":0.9,"empathy":0.2},{"suspicion":0.8}),
		_model_person(34,"Dagna Thorn","Quartermaster",["Frugal","Methodical"],{"discipline":0.9,"openness":0.3}),
		_model_person(35,"Pell Moss","Envoy",["Generous"],{"discipline":0.2,"openness":0.7},{"courage":0.2,"honesty":0.4}),
	]
	# Deterministic for life.
	for person in court:
		var a:=CV.for_person(person); var b:=CV.for_person(person)
		_expect(String(a.model)==String(b.model) and not String(a.model).is_empty(),"model assignment not deterministic for %s" % person.name)
	# Distinct within the room.
	var series:=StubHall.new()
	voice.hall=series; voice._used.clear()
	var a:=_audience("aud_models","gift")
	series.audiences["aud_models"]=a; series.courts["aud_models"]=court
	var s:Dictionary=voice.scene("aud_models")
	var seen:={}
	for member in [s.envoy]+(s.officials as Array):
		var m:=String(member.persona.get("model",""))
		_expect(not m.is_empty(),"%s has no voice model" % member.name)
		_expect(not seen.has(m),"two speakers share the %s manner" % m)
		seen[m]=true
		var brief:=CV.brief(member.persona)
		_expect("in the manner of" in brief and "never quoting" in brief,"brief lacks the manner instruction")
	# Every offline bank line is original and era-safe for its own era.
	for model_id in CV.MODEL_BANKS:
		for key in CV.MODEL_BANKS[model_id]:
			for line in CV.MODEL_BANKS[model_id][key]:
				_expect(CV.imitation_ok(String(line)),"bank line quotes or names a source: %s" % line)
				_expect(CV.lexicon_hits(String(line),[]).is_empty(),"bank line is anachronistic for the stone age: %s" % line)
	for m in CV.VOICE_MODELS:
		for line in m.examples: _expect(CV.imitation_ok(String(line)),"example quotes a source: %s" % line)
	_expect(not CV.imitation_ok("Four score and seven winters ago our elders came here."),"famous-line blocklist not applied")
	_expect(not CV.imitation_ok("As Atticus would say, be fair."),"source name blocklist not applied")
	_expect(CV.VOICE_MODELS.size()>=20,"voice model library too small")
	print("--- A COURT OF FIVE (with their visitor) ---")
	var rng:=RandomNumberGenerator.new(); rng.seed=77
	for member in [s.envoy]+(s.officials as Array):
		var p:Dictionary=member.persona
		var lines:PackedStringArray=PackedStringArray()
		var keys:Array=["tail","reply"] if String(member.key)=="envoy" else ["interject","aside"]
		var examples:Array=CV.model(String(p.get("model",""))).get("examples",[])
		for k in keys.size():
			var line:Dictionary=voice._say(s,member,CV.model_bank(p,String(keys[k])),rng)
			if line.is_empty(): line={"text":String(examples[mini(k,examples.size()-1)])}
			lines.append(String(line.text))
		print("  %s (%s) — manner: %s\n      \"%s\"\n      \"%s\"" % [String(member.name),String(p.get("title","")),String(p.get("model_name","")),lines[0],lines[1]])
	var leader:=CV.for_foreign_leader("civ_era_2")
	var examples:Array=CV.model(String(leader.model)).examples
	print("  %s (%s) — manner: %s\n      \"%s\"\n      \"%s\"" % [String(leader.name),String(leader.title),String(leader.model_name),String(examples[0]),String(examples[1])])
	voice.hall=stub; voice._used.clear()
	CV.knowledge_override.erase("player")

func _test_situations()->void:
	var series:=StubHall.new()
	voice.hall=series; voice._used.clear(); voice.force_offline=true
	# An arc: the petitioner acknowledges the unkept promise first.
	var a:=_audience("aud_arc","petition","court")
	a.petition={"topic":"follow_up","summary":"Tamsin Wolde asks again about a public council.","suggested_decree":"Hold a public council to hear the people"}
	GameState.elapsed_days=400
	a["situation"]={"type":"promise_followup","headline":"reminds you of a promise","summary":"Tamsin Wolde was promised a public council on day 250.",
		"occasion":{"type":"promise","text":"a promise left hanging","day":400,"crisis":false},"arc":{"branch":"promise_unkept","previous":{"day":250,"decree":"Hold a public council to hear the people"}}}
	series.audiences["aud_arc"]=a; series.order.push_front("aud_arc"); series.courts["aud_arc"]=_court()
	voice.open_scene("aud_arc")
	_expect(voice.remembered.has("aud_arc") and String(a.lines[0].text)==String(voice.remembered.aud_arc),"arc not acknowledged in the opening")
	_expect("public council" in String(a.lines[0].text).to_lower() and "last year" in String(a.lines[0].text).to_lower(),"arc opening lacks the matter and when: %s" % a.lines[0].text)
	# An occasion: the visitor opens from why they came.
	var b:=_audience("aud_occ","proposal")
	b["situation"]={"type":"recruitment_protest","headline":"protests your recruiters","summary":"The Velmari protest that your recruiters invited its households away (2 visits so far) and want it stopped.",
		"occasion":{"type":"recruitment_incident","text":"your recruiters invited the Velmari's households away","day":400,"crisis":false}}
	series.audiences["aud_occ"]=b; series.order.push_front("aud_occ"); series.courts["aud_occ"]=_court()
	voice.open_scene("aud_occ")
	var opening:=""
	for line in b.lines:
		if String(line.role)=="envoy": opening+=String(line.text)+" "
	_expect("luring" in opening or "talked into leaving" in opening,"occasion not spoken in the opening: %s" % opening)
	_expect("your word" in opening or "stops" in opening or "quarrel" in opening,"protest business missing: %s" % opening)
	_expect(not "recruiters invited" in opening,"occasion recited as data: %s" % opening)
	var prompt:String=voice.build_prompt(voice.scene("aud_occ"),"open",{})
	_expect("WHY THEY CAME" in prompt and "WORLD AS THESE PEOPLE KNOW IT" in prompt and "NOT YET KNOWN" in prompt,"prompt lacks occasion or world line")
	_expect("beer" in prompt.to_lower(),"world line does not name what is missing")
	var arc_prompt:String=voice.build_prompt(voice.scene("aud_arc"),"open",{})
	_expect("CONTINUING AN EARLIER AUDIENCE" in arc_prompt and "acknowledge" in arc_prompt,"prompt lacks the arc")
	# New answers close truthfully.
	voice.closing("aud_occ",{"ok":true,"outcome":"You agreed to restrain your recruiters.","reaction":"pleased","option_id":"restraint"})
	_expect(String(b.lines[-2].role)=="envoy" or String(b.lines[-1].role)=="envoy","restraint closing missing")
	print("--- SITUATIONS (offline) ---")
	for line in (a.lines as Array).slice(0,3)+(b.lines as Array): print("  %s%s: %s" % [String(line.speaker)," (aside)" if bool(line.aside) else "",String(line.text)])
	# The live validator drops anachronisms and quotations.
	var s:Dictionary=voice.scene("aud_occ")
	var kept:Array=voice.validate_lines([
		{"speaker_key":"envoy","text":"Let us seal it over a cask of beer.","aside":false},
		{"speaker_key":"envoy","text":"A house divided against itself will not stand, friend.","aside":false},
		{"speaker_key":"envoy","text":"As Lincoln said, be fair.","aside":false},
		{"speaker_key":"envoy","text":"Call off your people and our fires can share one smoke again.","aside":false}],s,"speak")
	_expect(kept.size()==1 and "share one smoke" in String(kept[0].text),"validator kept anachronism/quotation: %s" % JSON.stringify(kept))
	voice.hall=stub; voice._used.clear()

func _test_house_rules()->void:
	## Twelve audiences in one reign: one manner and one address per person for
	## life, nothing said twice, questions answered, short scenes, no dialect
	## flourishes on modelled speakers, era-true office titles.
	CV.knowledge_override["player"]=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	var series:=StubHall.new()
	voice.hall=series; voice._used.clear(); voice._mem_state={}; voice.force_offline=true
	var kinds:=["gift","request","threat","news","proposal","petition"]
	var questions:=["And if we say no?","Why now?","What do you gain from this?","Tell me plainly what you need.","Who else has heard it?","How long will your need last?"]
	var models:={}; var addresses:={}; var seen:={}
	var asked:=0; var answered:=0; var lines_total:=0; var short:=0
	var openers:={}
	for d in CV.DIALECTS:
		for o in d.open: openers[String(o)]=true
	for i in 12:
		var kind:String=kinds[i%kinds.size()]
		var id:="rule_%d" % i
		var a:=_era_audience(id,kind,i)
		a.civ_id="civ_rule_%d" % (i%3)
		if kind=="petition": a.speaker={"name":"Tamsin Wolde","title":"Quartermaster","person_id":7,"role":"official"}
		series.audiences[id]=a; series.order.push_front(id); series.courts[id]=_court()
		GameState.elapsed_days=50+i*60
		var s:Dictionary=voice.scene(id)
		for member in [s.envoy]+(s.officials as Array):
			var who:=String(member.persona.get("speaker_key",member.name))
			var held:Dictionary=models.get(who,{})
			held[String(member.persona.get("model",""))]=true; models[who]=held
		voice.open_scene(id)
		var question:String=questions[i%questions.size()]
		voice.player_speaks(id,question)
		if not voice.answer_bank(s,question).is_empty():
			asked+=1
			if bool(voice.answered.get(id,false)): answered+=1
		voice.closing(id,{"ok":true,"outcome":"Recorded.","reaction":["pleased","neutral","offended"][i%3],"option_id":{"gift":"accept","request":"refuse","threat":"defy","news":"thank","proposal":"decline","petition":"promise"}[kind]})
		a.status="resolved"
		var count:=0
		for line in a.lines:
			if String(line.role)=="ruler": continue
			count+=1; lines_total+=1
			var text:=String(line.text)
			if text.split(" ",false).size()<=20: short+=1
			var key:=Voice.norm_line(text)
			_expect(not seen.has(key),"said twice across audiences: %s" % text)
			seen[key]=true
			_expect(not openers.has(text.get_slice(" ",0)) and not text.begins_with("HA!"),"modelled speaker got a dialect flourish: %s" % text)
			var terms:Dictionary=addresses.get(String(line.speaker),{})
			for d in CV.DIALECTS:
				for term in d.address:
					if String(term) in text: terms[String(term)]=true
			addresses[String(line.speaker)]=terms
		_expect(count<=9,"%s ran to %d lines" % [id,count])
	for speaker in models: _expect((models[speaker] as Dictionary).size()==1,"%s changed manner: %s" % [speaker,JSON.stringify(models[speaker])])
	for speaker in addresses: _expect((addresses[speaker] as Dictionary).size()<=1,"%s addresses the ruler several ways: %s" % [speaker,JSON.stringify(addresses[speaker])])
	_expect(asked>0 and answered==asked,"questions answered from the facts: %d of %d" % [answered,asked])
	_expect(float(short)/maxf(1.0,float(lines_total))>=0.85,"too many long lines: %d of %d short" % [short,lines_total])
	_expect(float(lines_total)/12.0<=8.0,"audiences too long: %.1f lines on average" % (float(lines_total)/12.0))
	# Stone-age office titles read like a band, not a republic.
	var stage:=int(GovernmentPeopleSystem.government_stage)
	GovernmentPeopleSystem.government_stage=3
	var modern:=RegEx.new(); modern.compile("(?i)(secretary|federal|mayor|minister|convenor|delegate|councillor|prefect|chancellor|director|governor)")
	for office in GovernmentPeopleSystem.active_offices():
		_expect(modern.search(String(office.title))==null,"stone-age title reads modern: %s" % office.title)
	_expect(modern.search(GovernmentPeopleSystem.settlement_leader_title())==null,"stone-age settlement title reads modern")
	GovernmentPeopleSystem.government_stage=stage
	print("house rules: %d lines over 12 audiences, %d short, %d/%d questions answered, %d speakers one manner each" % [lines_total,short,answered,asked,models.size()])
	voice.hall=stub; voice._used.clear(); voice._mem_state={}
	CV.knowledge_override.erase("player")

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
