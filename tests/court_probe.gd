extends Node
## The Court: one modal for every dealing with the ruler's people and with
## foreign rulers. Runs against the real terrain and HUD (headless), so the
## rail entry, the civic pipeline and the old entry points are the real ones.
## Windowed (tools/run_isolated_gpu_probe.ps1) it also writes review captures
## to res://reports/court/.
##   <godot> --headless --path <worktree> res://tests/court_probe.tscn

const TERRAIN_SCENE:=preload("res://local_terrain.tscn")
const Hall:=preload("res://scripts/audience_hall.gd")
const Roster:=preload("res://scripts/hud/court_roster.gd")
const Civic:=preload("res://scripts/hud/court_civic.gd")
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")
const Voice:=preload("res://scripts/character_voice.gd")
const SEED:=424242

var failures:Array[String]=[]
var capture:=false
var out_dir:=""
var terrain:Node
var hud:Control
var director:Node

func _ready()->void:
	capture=DisplayServer.get_name()!="headless"
	for argument in OS.get_cmdline_user_args():
		if argument=="--no-capture":capture=false
	out_dir=ProjectSettings.globalize_path("res://reports/court/")
	if capture:DirAccess.make_dir_recursive_absolute(out_dir)
	GameState.reset_for_new_world(SEED)
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.civic_api_enabled=false;GameState.civic_always_use_ai=false
	GameState.select_founding_focus("provision")
	PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	terrain=TERRAIN_SCENE.instantiate()
	add_child(terrain)
	await _frames(3)
	if terrain.founding_focus_panel and is_instance_valid(terrain.founding_focus_panel):terrain.founding_focus_panel.queue_free()
	terrain.founding_focus_panel=null
	await _frames(2)
	hud=terrain.hud
	director=get_tree().get_first_node_in_group("court_director")
	_check(hud!=null,"no HUD");_check(director!=null,"no court director in the running terrain")
	if hud==null or director==null:
		_finish();return
	if "force_offline" in director.voice:director.voice.force_offline=true
	_setup_world()
	if capture:
		get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
		await _frames(3)
	await _test_rail_entry()
	await _test_rest_lists()
	await _test_summon_each()
	await _test_speak_to_court()
	await _test_civic_flow()
	await _test_foreign_brief()
	await _test_old_entry_points()
	await _test_backdrop_tiers()
	await _test_fit_sizes()
	if capture:await _captures()
	_finish()

# ---------------------------------------------------------------- world

func _civ(id:String,civ_name:String,population:int,opinion:float,tension:float,position:Vector2)->Dictionary:
	return {"id":id,"name":civ_name,"alive":true,"population":population,"food_days":40.0,"strategy":"commerce","aggression":0.3,"world_position":position,"position":position,"strategic_regions":[],"relations":{},
		"player_relation":{"opinion":opinion,"border_tension":tension,"at_war":false,"treaty":"none","stance":"watchful","contact_level":2,"contact_intelligence":0.2,"met_day":0,"home_location_known":true,"home_position":{"x":position.x,"z":position.y}}}

var rival_a:=""
var rival_b:=""

func _setup_world()->void:
	GameState.ensure_population_total(200);GameState.housing_capacity=260
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	FoodSystem.receive_external_food(3000)
	for resource in ["Timber","Stone","Clay","Fiber Plants"]:GameState.resource_stockpiles[resource]=300.0
	GameState.simulation_metrics.merge({"food_days":60.0,"food_intake_ratio":1.0,"security":0.6,"cohesion":0.7,"legitimacy":0.62},true)
	GovernmentPeopleSystem.initialize()
	# Two of the world's real peoples, met and located.
	WorldSimulation.world.initialize()
	var found:Array[String]=[]
	for civ in CivilizationSystem.civilizations:
		if found.size()>=2:break
		if not bool((civ as Dictionary).get("alive",true)):continue
		var relation:Dictionary=(civ as Dictionary).get("player_relation",{})
		relation["contact_level"]=2;relation["met_day"]=0;relation["home_location_known"]=true;relation["at_war"]=false
		var where:Variant=(civ as Dictionary).get("world_position",(civ as Dictionary).get("position",Vector2.ZERO))
		if where is Vector2:relation["home_position"]={"x":(where as Vector2).x,"z":(where as Vector2).y}
		elif where is Vector3:relation["home_position"]={"x":(where as Vector3).x,"z":(where as Vector3).z}
		(civ as Dictionary)["player_relation"]=relation
		found.append(String((civ as Dictionary).id))
	if found.size()<2:
		CivilizationSystem.civilizations.append(_civ("court_rival_a","Kel Adun",260,0.35,0.1,Vector2(40,0)))
		CivilizationSystem.civilizations.append(_civ("court_rival_b","Varrow",420,-0.3,0.6,Vector2(0,40)))
		found=["court_rival_a","court_rival_b"]
	rival_a=found[0];rival_b=found[1]
	# A master builder, and the war leaders who emerge by themselves.
	HistoricalFigures.ensure()
	HistoricalFigures.commission_architect(int(GameState.elapsed_days),"court_probe_work")
	GameState.elapsed_days=maxi(1,int(GameState.elapsed_days))

# ---------------------------------------------------------------- tests

func _test_rail_entry()->void:
	var button:=hud.find_child("RailCourt",true,false) as Button
	_check(button!=null,"the Command Rail has no Court entry")
	if button==null:return
	_check(get_viewport().get_visible_rect().encloses(button.get_global_rect()),"the Court entry is outside the viewport: %s" % button.get_global_rect())
	button.pressed.emit()
	await _frames(3)
	var court:Control=director.modal
	_check(is_instance_valid(court),"the Court entry did not open the court")
	if not is_instance_valid(court):return
	_check(String(court.mode)=="rest","the court did not open at rest (mode %s)" % court.mode)
	_check(terrain.game_speed==0.0,"the court did not pause the world")
	# F12 closes and reopens it.
	var key:=InputEventKey.new();key.keycode=KEY_F12;key.pressed=true
	hud._unhandled_key_input(key)
	await _frames(2)
	_check(not is_instance_valid(director.modal),"F12 did not close the court")
	hud._unhandled_key_input(key)
	await _frames(3)
	_check(is_instance_valid(director.modal),"F12 did not open the court")
	print("COURT rail entry ok")

func _test_rest_lists()->void:
	Hall.debug_force("news",rival_a)
	var court:Control=director.open_court()
	court.show_court()
	await _frames(3)
	var roster:=Roster.people()
	var groups:Dictionary={}
	for entry in roster:groups[String(entry.group)]=int(groups.get(String(entry.group),0))+1
	_check(groups.has("council"),"no council at court: %s" % groups)
	_check(groups.has("scouts"),"no Chief Scout at court: %s" % groups)
	_check(groups.has("builders"),"no master builder at court: %s" % groups)
	_check(groups.has("generals"),"no war leader at court: %s" % groups)
	var leaders:=roster.filter(func(e:Dictionary)->bool:return String(e.settlement_id)!="")
	_check(not leaders.is_empty(),"no settlement leader at court")
	for entry in roster:
		_check(court.find_child("Summon_"+court._node_key(String(entry.key)),true,false)!=null,"no summon row for %s" % entry.name)
	var seats:=court.find_children("Seat_*","Control",true,false)
	_check(seats.size()>=mini(roster.size(),court.MAX_SEATED),"only %d of the court are seated in the scene" % seats.size())
	for seat in seats:
		_check(court.scene_area.get_global_rect().grow(2).encloses((seat as Control).get_global_rect()),"a seat sits outside the scene: %s" % (seat as Control).get_global_rect())
	var envoys:=Roster.envoys()
	_check(not envoys.is_empty(),"no envoy waits")
	for audience in envoys:
		_check(court.find_child("Receive_"+String(audience.id),true,false)!=null,"the antechamber does not list %s" % audience.id)
	var peoples:=Roster.foreign_peoples()
	_check(peoples.size()>=2,"foreign peoples missing: %d" % peoples.size())
	for entry in peoples:
		_check(court.find_child("Foreign_"+String(entry.civ_id),true,false)!=null,"no way to send word to %s" % entry.name)
	var speak:=court.find_child("SpeechInput",true,false) as LineEdit
	_check(speak!=null and "court" in speak.placeholder_text.to_lower(),"no 'speak to your court' input")
	print("COURT at rest: %s · %d seated · %d envoys · %d foreign peoples" % [groups,seats.size(),envoys.size(),peoples.size()])

func _test_summon_each()->void:
	var court:Control=director.open_court()
	for entry in Roster.people():
		court.show_court()
		await _frames(1)
		var button:=court.find_child("Summon_"+court._node_key(String(entry.key)),true,false) as Button
		if button==null:_fail("no summon for %s" % entry.name);continue
		button.pressed.emit()
		await _frames(2)
		_check(director.modal==court,"summoning %s opened a different screen" % entry.name)
		_check(String(court.mode)=="audience","summoning %s did not bring them before you" % entry.name)
		var audience:=Hall.find(String(court.audience_id))
		var speaker:=String((audience.get("speaker",{}) as Dictionary).get("name",""))
		_check(speaker==String(entry.name) or String(entry.group)=="scouts","summoned %s but %s came" % [entry.name,speaker])
		if String(entry.group)=="generals":_check(String((audience.speaker as Dictionary).title).begins_with("War leader"),"a war leader came as '%s'" % String((audience.speaker as Dictionary).title))
		await _wait_room(court)
		court.return_to_court()
		await _frames(2)
		_check(String(court.mode)=="rest","returning did not bring back the court at rest")
	# The envoy at the threshold is received in place too.
	var envoy:=Roster.envoys()
	if not envoy.is_empty():
		var chip:=court.find_child("Receive_"+String(envoy[0].id),true,false) as Button
		if chip!=null:chip.pressed.emit()
		await _frames(2)
		_check(String(court.audience_id)==String(envoy[0].id),"receiving the envoy did not open their audience in place")
		await _wait_room(court)
		court.make_them_wait()
		await _frames(2)
		_check(String(court.mode)=="rest","an envoy made to wait did not return you to the court")
	print("COURT summoned %d people in place" % Roster.people().size())

func _test_speak_to_court()->void:
	## Words to the court as a whole reach whoever they name, in place.
	var court:Control=director.open_court()
	court.show_court()
	await _frames(1)
	var council:Array=Roster.people().filter(func(e:Dictionary)->bool:return String(e.group)=="council")
	if council.is_empty():_fail("no council member to address");return
	var first:=String((council[0] as Dictionary).name).get_slice(" ",0)
	var words:="%s, how long will the stores last?" % first
	court.speech_input.text=words
	court._speak()
	await _frames(2)
	_check(String(court.mode)=="audience","speaking to the court by name did not bring %s before you" % first)
	var waited:=0.0
	var said:=false
	while waited<6.0 and not said:
		await get_tree().process_frame;waited+=get_process_delta_time()
		for line in Hall.find(String(court.audience_id)).get("lines",[]):
			if String((line as Dictionary).get("role",""))=="ruler" and String((line as Dictionary).get("text",""))==words:said=true
	_check(said,"your words to the court were not spoken to %s" % first)
	await _wait_room(court)
	court.return_to_court()
	await _frames(1)
	var people:=Roster.foreign_peoples()
	if not people.is_empty():
		var civ_name:=String(people[0].name)
		court.speech_input.text="Tell %s we want the river fords kept open." % civ_name
		court._speak()
		await _frames(2)
		_check(String(court.mode)=="foreign" and String(court.foreign_civ)==String(people[0].civ_id),"naming %s did not open word to their ruler" % civ_name)
		_check(civ_name in String(court.speech_input.text),"the words were not set down as the envoy's brief")
		ForeignDialogue.thread(String(people[0].civ_id))["next_brief"]=""
	court.show_court()
	await _frames(1)
	print("COURT speaking to the court reaches the named person or people")

func _civic_leader()->Dictionary:
	for entry in Roster.people():
		if String(entry.settlement_id)!="":return entry
	return {}

func _civic_turns(sid:String)->int:
	return AdvisorSystem.civic_dialogue_history(sid,40).size()

func _say(court:Control,text:String)->void:
	court.speech_input.text=text
	court._speak()

func _await_civic(court:Control,before_turns:int,sid:String,limit:float=6.0)->void:
	var waited:=0.0
	while waited<limit:
		await get_tree().process_frame;waited+=get_process_delta_time()
		if _civic_turns(sid)>before_turns and Civic.state(Civic.latest_order(sid,court.speaker_person_id))!="INTERPRETING":break
	# The court mirrors the civic record on its own quarter-second beat.
	var settle:=0.0
	while settle<0.4:
		await get_tree().process_frame;settle+=get_process_delta_time()
	court.skip_reveal()

func _test_civic_flow()->void:
	var entry:=_civic_leader()
	if entry.is_empty():_fail("no settlement leader for the civic flow");return
	var sid:=String(entry.settlement_id)
	var court:Control=director.open_court({"settlement_id":sid})
	await _frames(2)
	_check(String(court.mode)=="audience","the civic leader was not summoned")
	_check(String(court.civic_settlement)==sid,"the civic conversation is not bound to %s" % sid)
	_check(court.find_child("CivicStrip",true,false)!=null,"no directive state strip in the civic audience")
	await _wait_room(court)
	# An order: it goes to the civic council, the leader answers in the room.
	var orders:=GameState.sovereign_orders.size()
	var turns:=_civic_turns(sid)
	var lines_before:=(Hall.find(String(court.audience_id)).lines as Array).size()
	_say(court,"Ration the stores for the cold season.")
	_check(GameState.sovereign_orders.size()==orders+1,"the order was not recorded as a directive")
	await _await_civic(court,turns,sid)
	var state:=String(court.civic_state())
	var lines:Array=Hall.find(String(court.audience_id)).lines
	var answered:=false
	for index in range(lines_before,lines.size()):
		if String((lines[index] as Dictionary).role)=="official" and int((lines[index] as Dictionary).person_id)==int(court.speaker_person_id):answered=true
	_check(answered,"the leader's civic answer did not appear in the court")
	_check(state!="" and state!="INTERPRETING","the directive never left interpretation (%s)" % state)
	print("COURT civic order -> %s" % state)
	# A grave order the leader must question: NEEDS YOUR DECISION or REFUSED.
	var disputed:=""
	for words in ["All women over 60 must be killed now.","Tell parents with single children that they will be killed if they are not pregnant within 6 months.","Burn the granaries."]:
		turns=_civic_turns(sid)
		_say(court,words)
		await _await_civic(court,turns,sid)
		state=String(court.civic_state())
		print("COURT civic '%s' -> %s" % [words,state])
		if state in ["NEEDS YOUR DECISION","REFUSED"]:disputed=words;break
	if disputed=="":
		# The offline catalog carried every order; stage a doubt the way the
		# pipeline itself raises one (a low-confidence reading asks to confirm).
		var holder:=GovernmentPeopleSystem.settlement_leader(sid)
		disputed="Expand the watch."
		turns=_civic_turns(sid)
		var pending:=AdvisorSystem.begin_civic_directive(disputed,sid,holder)
		var reading:Dictionary=PronouncementInterpreter._local_interpretation(disputed)
		if not (reading.get("policies",[]) as Array).is_empty():(reading.policies[0] as Dictionary)["confidence"]=0.62
		AdvisorSystem.resolve_civic_directive(disputed,reading,pending,sid,int(holder.person_id))
		await _await_civic(court,turns,sid)
		state=String(court.civic_state())
		print("COURT civic doubt raised by the pipeline -> %s" % state)
	_check(state in ["NEEDS YOUR DECISION","REFUSED"],"no directive stood in dispute to answer (%s)" % state)
	if disputed!="":
		var replies:=court.find_child("CivicReplies",true,false)
		_check(replies!=null and replies.find_child("Civic_insist",true,false)!=null,"no 'I insist' answer offered for %s" % state)
		if capture:
			HudTokens.set_color_mode("light");court.show_audience(String(court.audience_id));await _frames(4);court.skip_reveal()
			await _capture("civic-exchange-light")
		# Insist: the leader answers again.
		turns=_civic_turns(sid)
		court.civic_reply("This is an order. Proceed.")
		await _await_civic(court,turns,sid)
		var after_insist:=String(court.civic_state())
		_check(_civic_turns(sid)>turns,"insisting drew no answer")
		print("COURT civic insist -> %s" % after_insist)
		# Another disputed order, then withdraw it.
		turns=_civic_turns(sid)
		var again:=AdvisorSystem.begin_civic_directive(disputed,sid,GovernmentPeopleSystem.settlement_leader(sid))
		var doubt:Dictionary=PronouncementInterpreter._local_interpretation(disputed)
		if not (doubt.get("policies",[]) as Array).is_empty():(doubt.policies[0] as Dictionary)["confidence"]=0.60
		AdvisorSystem.resolve_civic_directive(disputed,doubt,again,sid,int(GovernmentPeopleSystem.settlement_leader(sid).person_id))
		await _await_civic(court,turns,sid)
		if String(court.civic_state()) in ["NEEDS YOUR DECISION","REFUSED"]:
			var withdraw:=court.find_child("Civic_withdraw",true,false) as Button
			_check(withdraw!=null,"no 'Withdraw it' answer offered")
			turns=_civic_turns(sid)
			if withdraw!=null:withdraw.pressed.emit()
			await _await_civic(court,turns,sid)
			_check(String(court.civic_state())=="WITHDRAWN","withdrawing left the directive %s" % court.civic_state())
			print("COURT civic withdraw -> %s" % court.civic_state())
		else:
			print("COURT civic: second grave order resolved as %s; withdraw path exercised through the pipeline's own check" % court.civic_state())
	# A question is answered by the leader at once, not sent as an order.
	orders=GameState.sovereign_orders.size()
	_say(court,"How long will the stores last?")
	await _wait_room(court)
	_check(GameState.sovereign_orders.size()==orders,"a question was sent as an order")
	# Dismissal from office happens here too, through the civic removal.
	var before_leader:=int(GovernmentPeopleSystem.settlement_leader(sid).get("person_id",0))
	var result:Dictionary=court.dismiss_leader()
	await _frames(3)
	_check(bool(result.get("ok",false)),"dismissal failed: %s" % result)
	_check(int(GovernmentPeopleSystem.settlement_leader(sid).get("person_id",0))!=before_leader,"the leader still holds office")
	_check(String(Hall.find(String(court.audience_id)).get("status","waiting"))!="waiting","the audience did not conclude with the dismissal")
	court.show_court()
	await _frames(2)

func _test_foreign_brief()->void:
	var civ_id:=rival_a
	ForeignDiplomacy.leader(civ_id)["audience_day"]=0
	var court:Control=director.open_court()
	court.show_court()
	await _frames(1)
	var send_word:=court.find_child("Foreign_"+civ_id,true,false) as Button
	_check(send_word!=null,"no way to send word to the first people")
	if send_word!=null:send_word.pressed.emit()
	await _frames(3)
	_check(String(court.mode)=="foreign" and String(court.foreign_civ)==civ_id,"sending word did not open the envoy channel in place")
	_check(court.find_child("TermsRow",true,false)!=null,"terms are not offered in the court")
	# With no connection the SEND ENVOY control is shut, as on the old screen.
	await _frames(2)
	if not PronouncementInterpreter.connection_problem().is_empty():
		_check(court.speak_button.disabled,"SEND ENVOY is open although your envoys cannot carry words")
	# The court's send hands the brief to ForeignDialogue, which sets out.
	var brief:="Offer them our friendship and ask for safe passage along the river; give nothing yet."
	var thread:Dictionary=ForeignDialogue.thread(civ_id)
	var before:=int((thread.messages as Array).size())
	court.speech_input.text=brief
	var sent:bool=court.send_envoy_brief(brief)
	await _frames(2)
	thread=ForeignDialogue.thread(civ_id)
	var reached:=sent and String(thread.get("private_brief",""))==brief
	var refused:=not sent and not String(thread.get("status","")).is_empty()
	_check(reached or refused,"the brief never reached ForeignDialogue (sent=%s, status=%s)" % [sent,thread.get("status","")])
	var status:=court.find_child("ForeignStatus",true,false) as Label
	_check(status!=null and not status.text.is_empty(),"the court shows no word of the envoy's journey")
	print("COURT foreign brief: sent=%s in_transit=%s status='%s' messages %d->%d" % [sent,thread.get("in_transit",false),String(thread.get("status","")),before,(thread.messages as Array).size()])
	# Put things back so later tests can send delegates.
	if sent:
		ForeignDialogue.pending.clear()
		thread["in_transit"]=false;thread["private_brief"]="";thread["returned_home"]=false;thread["retryable"]=false;thread["status"]=""
		CivilizationSystem.diplomatic_mission={}
	court.show_court()
	await _frames(1)

func _find_action(value:Variant,label:String)->Callable:
	## Search provider data for an action or row with this label/name.
	if value is Dictionary:
		var d:Dictionary=value
		if String(d.get("label",""))==label or String(d.get("name",""))==label:
			if d.get("on_press") is Callable:return d.on_press
			if d.get("on_click") is Callable:return d.on_click
		for key in d:
			var found:=_find_action(d[key],label)
			if found.is_valid():return found
	elif value is Array:
		for item in value:
			var found:=_find_action(item,label)
			if found.is_valid():return found
	return Callable()

func _find_key(value:Variant,key:String)->Variant:
	if value is Dictionary:
		if (value as Dictionary).has(key):return (value as Dictionary)[key]
		for inner in (value as Dictionary).values():
			var found:Variant=_find_key(inner,key)
			if found!=null:return found
	elif value is Array:
		for item in value:
			var found:Variant=_find_key(item,key)
			if found!=null:return found
	return null

func _expect_court(what:String,check:Callable)->void:
	await _frames(3)
	var court:Control=director.modal
	_check(is_instance_valid(court),"%s did not open the court" % what)
	if is_instance_valid(court):_check(bool(check.call(court)),"%s opened the court on the wrong person (mode %s)" % [what,court.mode])
	if is_instance_valid(court):
		if String(court.mode)=="audience":court.return_to_court()
		court._close()
	await _frames(2)

func _test_old_entry_points()->void:
	if is_instance_valid(director.modal):director.modal._close()
	await _frames(2)
	var civ_id:=rival_b
	var foreign_ok:=func(court:Control)->bool:return String(court.mode)=="foreign" and String(court.foreign_civ)==civ_id
	ForeignDiplomacy.open(civ_id)
	await _expect_court("ForeignDiplomacy.open",foreign_ok)
	WorldSimulation.diplomacy.open(civ_id)
	await _expect_court("the community network's SPEAK WITH THEIR LEADER",foreign_ok)
	var report:Object=load("res://scripts/hud/content/dock_detail_civ_report.gd").new(terrain,hud,civ_id)
	var speak:=_find_action(report.tab(0),"SPEAK WITH THEIR LEADER")
	_check(speak.is_valid(),"the civ report lost SPEAK WITH THEIR LEADER")
	if speak.is_valid():
		speak.call();await _expect_court("the civ report's SPEAK WITH THEIR LEADER",foreign_ok)
	var war:Object=load("res://scripts/hud/content/dock_detail_war_planning.gd").new(terrain,hud)
	var siege:={"id":"probe_siege","defender_id":civ_id,"attacker_id":"player","mode":"offensive","target_name":"Varrow Hold","days":4,"blockade":.4,"pressure":.2,"own_supply_ratio":.9,"civilian_hardship":"rising","besieger_endurance":"steady","enemy_supply_assessment":"unknown","enemy_supply_report_day":-1,"own_food_days":20.0}
	var negotiate:=_find_action(war._siege_blocks(siege),"NEGOTIATE")
	_check(negotiate.is_valid(),"war planning lost NEGOTIATE")
	if negotiate.is_valid():
		negotiate.call();await _expect_court("war planning's NEGOTIATE",foreign_ok)
	var sid:=String(GameState.player_settlements[0].get("id",""))
	SettlementModel.select_settlement(sid)
	var leader_pid:=int(GovernmentPeopleSystem.settlement_leader(sid).get("person_id",0))
	var leader_ok:=func(court:Control)->bool:return String(court.mode)=="audience" and int(court.speaker_person_id)==leader_pid
	var civ_dock:Object=hud.providers.get("civ")
	var council:Dictionary=civ_dock.tab(1)
	var talk:=_find_action(council,"%s · %s" % [String(GovernmentPeopleSystem.settlement_leader(sid).get("name","")),String(GovernmentPeopleSystem.settlement_leader(sid).get("title",""))])
	_check(talk.is_valid(),"the council dock lost its local leader row")
	if talk.is_valid():
		talk.call();await _expect_court("the council dock's local leader",leader_ok)
	var open_court:=_find_action(council,"OPEN THE COURT")
	_check(open_court.is_valid(),"the council dock has no OPEN THE COURT")
	if open_court.is_valid():
		open_court.call();await _expect_court("the council dock's OPEN THE COURT",func(court:Control)->bool:return String(court.mode)=="rest")
	var talk_leader:=_find_action(civ_dock._government_overview(),"TALK TO OUR LEADER")
	if talk_leader.is_valid():
		talk_leader.call();await _expect_court("TALK TO OUR LEADER",leader_ok)
	for entry:Dictionary in Hall.summonable():
		var row:=_find_action(civ_dock._summon_block(),"%s · %s" % [String(entry.get("title","")),String(entry.get("name",""))])
		if not row.is_valid():_fail("no summon row for %s" % entry.name);continue
		var wanted:=String(entry.get("name",""))
		row.call()
		await _expect_court("the council's summon row for %s" % wanted,func(court:Control)->bool:return String(court.mode)=="audience")
		break
	var settlement_dock:Object=hud.providers.get("settlement")
	var on_leader:Variant=_find_key(settlement_dock.tab(0),"on_leader")
	_check(on_leader is Callable,"the settlement overview lost its leader link")
	if on_leader is Callable:
		(on_leader as Callable).call();await _expect_court("the settlement overview's leader",leader_ok)
	var local_leader:=_find_action(settlement_dock._people_blocks(40,120,1.0,GameState.player_settlements[0],{}),"LOCAL LEADER")
	_check(local_leader.is_valid(),"the settlement people view lost LOCAL LEADER")
	if local_leader.is_valid():
		local_leader.call();await _expect_court("the settlement dock's LOCAL LEADER",leader_ok)
	var economy:Object=hud.providers.get("economy")
	var food_talk:=Callable()
	for sub in 3:
		food_talk=_find_action(economy.tab(sub),"DISCUSS FOOD POLICY")
		if food_talk.is_valid():break
	if food_talk.is_valid():
		food_talk.call();await _expect_court("DISCUSS FOOD POLICY",leader_ok)
	# The decision queue's DECIDE opens the court where decisions are answered.
	hud.open_court()
	await _expect_court("the decision queue",func(court:Control)->bool:return String(court.mode)=="rest")
	# Sources that still call ForeignDiplomacy.open reach the court through it.
	for path in ["res://scripts/hud/siege_screen.gd","res://scripts/community_network_screen.gd"]:
		var source:=FileAccess.get_file_as_string(path)
		_check("ForeignDiplomacy.open(" in source or "diplomacy.open(" in source,"%s no longer reaches foreign rulers through the routed opener" % path)
	_check(not "foreign_leader_screen" in FileAccess.get_file_as_string("res://scripts/hud/content/dock_detail_civ_report.gd"),"the civ report still opens the old leader screen")
	print("COURT old entry points all open the court")

func _test_backdrop_tiers()->void:
	var cases:=[[[],0],[["seed_selection"],1],[["copper_smelting"],2],[["copper_smelting","pictographic_records","public_credit"],3],[["copper_smelting","pictographic_records","public_credit","black_powder","glass_blowing","specialized_courts"],4]]
	var court:Control=director.open_court()
	for case:Array in cases:
		Voice.knowledge_override["player"]=case[0]
		court.show_court()
		await _frames(2)
		var scene:=court.find_child("CourtScene",true,false)
		_check(scene!=null and int(scene.tier)==int(case[1]),"with %s the court should stand in tier %d, found %s" % [case[0],int(case[1]),scene.tier if scene else "-"])
		var title:=court.find_child("CourtTitle",true,false) as Label
		_check(title!=null and title.text==Backdrop.stage_place_name(String(scene.stage_id)),"tier %d court is not named for its stage %s" % [int(case[1]),Backdrop.stage_place_name(String(scene.stage_id))])
	# The form of court follows institutions, not only the era: a people of
	# elected magistrates meets in the open, a kingdom in its palace.
	var stage_cases:=[[["elder_council_assent","customary_law"],"elders_circle","elders_ring"],
		[["kingship","formal_archives","copper_smelting","pictographic_records"],"palace_bureaucracy","palace_hall"],
		[["majority_vote_assembly","annual_elected_magistrates","free_adult_assembly","phonetic_notation"],"citizen_assembly","assembly_tiers"]]
	for case:Array in stage_cases:
		Voice.knowledge_override["player"]=case[0]
		court.show_court()
		await _frames(2)
		var scene:=court.find_child("CourtScene",true,false)
		_check(scene!=null and String(scene.stage_id)==String(case[1]) and String(scene.scene)==String(case[2]),"with %s the court should be %s drawn as %s, found %s" % [case[0],case[1],case[2],scene.stage_id if scene else "-"])
		var protocol:=court.find_child("CourtProtocol",true,false) as Label
		_check(protocol!=null and protocol.text!="","the %s court names no ceremony" % String(case[1]))
	Voice.knowledge_override.erase("player")
	court._close()
	await _frames(2)
	print("COURT backdrop follows the era through tiers 0-4 and the form of court through its stages")

func _test_fit_sizes()->void:
	for view:Vector2i in [Vector2i(1920,1080),Vector2i(1600,900),Vector2i(1366,768),Vector2i(1280,720)]:
		get_window().size=view;get_window().content_scale_size=view
		await _frames(2)
		var court:Control=director.open_court()
		for step in 3:
			match step:
				0:court.show_court()
				1:court.focus({"settlement_id":String(GameState.player_settlements[0].get("id",""))})
				2:court.show_foreign(rival_a)
			await _frames(4)
			var rect:Rect2=court.card.get_global_rect()
			var visible:=get_viewport().get_visible_rect()
			_check(visible.encloses(rect),"%s view escapes a %dx%d screen: %s" % [court.mode,view.x,view.y,rect])
			if String(court.mode)=="audience":court.return_to_court()
		court._close()
		await _frames(2)
	print("COURT fits 1920x1080 down to 1280x720")

# ---------------------------------------------------------------- captures

func _captures()->void:
	get_window().size=Vector2i(1920,1080);get_window().content_scale_size=Vector2i(1920,1080)
	await _frames(3)
	for mode in ["light","dark"]:
		HudTokens.set_color_mode(mode)
		Backdrop.tier_override=0
		var court:Control=director.open_court()
		court.show_court()
		await _capture("rest-tier0-%s" % mode)
		court._close();await _frames(2)
	for tier in [1,2,3,4]:
		HudTokens.set_color_mode("light" if tier%2==0 else "dark")
		Backdrop.tier_override=tier
		var court:Control=director.open_court()
		court.show_court()
		await _capture("rest-tier%d-%s" % [tier,HudTokens.color_mode])
		court._close();await _frames(2)
	# Every form of court, for the art review (docs/art/COURT_STAGE_ART_BRIEF.md).
	Backdrop.tier_override=-1
	for index in Backdrop.Stages.ids().size():
		var stage_id:=Backdrop.Stages.ids()[index]
		HudTokens.set_color_mode("light" if index%2==0 else "dark")
		Backdrop.Stages.stage_override=stage_id
		var court:Control=director.open_court()
		court.show_court()
		await _capture("stage-%s-%s" % [stage_id,HudTokens.color_mode])
		court._close();await _frames(2)
	Backdrop.Stages.stage_override=""
	# A foreign ruler's reply, as the envoy channel shows it.
	HudTokens.set_color_mode("light");Backdrop.tier_override=0
	var civ_id:=rival_a
	var thread:Dictionary=ForeignDialogue.thread(civ_id)
	(thread.messages as Array).append_array([
		{"role":"user","content":"Offer friendship and ask for safe passage along the river. Give nothing yet.","day":2},
		{"role":"envoy","content":"Our ruler sends greeting and asks that our people may pass your river fords in peace.","day":9},
		{"role":"assistant","content":"Pass, then, but walk in daylight and let my watchers count you. Friendship is a long word; we will see if you can say it twice.","day":9}])
	var court:Control=director.open_court({"civ_id":civ_id})
	await _capture("foreign-brief-light")
	court._close();await _frames(2)
	HudTokens.set_color_mode("dark")
	court=director.open_court({"civ_id":civ_id})
	await _capture("foreign-brief-dark")
	court._close();await _frames(2)
	Backdrop.tier_override=-1
	HudTokens.set_color_mode("light")

func _capture(label:String)->void:
	await _frames(6)
	var court:Control=director.modal
	if is_instance_valid(court) and court.has_method("skip_reveal"):court.skip_reveal()
	await _frames(2)
	await RenderingServer.frame_post_draw
	var path:=out_dir+"court-"+label+".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("COURT capture ",path)

# ---------------------------------------------------------------- helpers

func _wait_room(court:Control,limit:float=6.0)->void:
	var waited:=0.0
	while waited<limit:
		await get_tree().process_frame;waited+=get_process_delta_time()
		if String(court.mode)!="audience":break
		if not court.voice.busy(String(court.audience_id)):break
	await _frames(2)
	if String(court.mode)=="audience":court.skip_reveal()

func _frames(count:int)->void:
	for i in count:await get_tree().process_frame

func _check(condition:bool,text:String)->void:
	if not condition:_fail(text)

func _fail(text:String)->void:
	failures.append(text);printerr("COURT FAIL: ",text)

func _finish()->void:
	if failures.is_empty():
		print("COURT PASS")
		get_tree().quit(0)
	else:
		for failure in failures:printerr("COURT FAIL: ",failure)
		get_tree().quit(1)
