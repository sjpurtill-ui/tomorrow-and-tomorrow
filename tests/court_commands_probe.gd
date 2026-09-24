extends Node
## The god's word is law. Typed orders in the Court are read as speech acts,
## resolved to the people present, decided by the engine (obedience from love
## and dread) and carried out through the real systems; the voice only
## describes what happened, with a bracketed stage direction.
## Covers the reported scene ("Ansel kill him!" in a summoned audience with the
## War Leader), hesitation then "I DEMAND IT!", pronoun and title resolution,
## real goods, exile, the civic pipeline and the custom-directive path,
## the rare refusal (flight or seizure), the filler/refusal validators, and a
## mocked live model for both the classifier and the staged reaction.
##   <godot> --headless --path <worktree> res://tests/court_commands_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const Divine:=preload("res://scripts/divine_regard.gd")
const CC:=preload("res://scripts/court_commands.gd")
const CV:=preload("res://scripts/character_voice.gd")
const METAL_WORDS:="(?i)\\b(sword|iron|bronze|copper|steel|blade of metal)\\b"

var failures:Array[String]=[]
var transcripts:Array[String]=[]
var director:Node
var terrain:Node
var ids:Dictionary={}   # role -> person_id

func _fail(text:String)->void:
	failures.append(text); printerr("COURT_COMMANDS FAIL: ",text)

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

func _say(modal:Control,id:String,text:String)->void:
	var before:=(Hall.find(id).get("lines",[]) as Array).size()
	modal.speech_input.text=text
	modal._speak()
	await _wait(modal,id,before+2)

func _ready()->void:
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	GameState.ensure_population_total(800)
	WorldSimulation.state.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	terrain=ModalProbe.TerrainDouble.new(); terrain.name="TerrainDouble"; add_child(terrain)
	director=Director.new(); director.terrain=terrain; add_child(director)
	if "force_offline" in director.voice: director.voice.force_offline=true
	await _frames(2)
	GameState.elapsed_days=40
	_cast()
	if ids.size()<4: _fail("need four officials, have %s" % str(ids)); _finish(); return
	_test_classifier()
	_test_validators()
	await _test_screenshot_scene()
	await _test_hesitation_then_demand()
	await _test_goods_and_exile()
	await _test_orders()
	await _test_refusal()
	_test_refusal_is_rare()
	await _test_live()
	await _test_envoy()
	_finish()

# ---------------------------------------------------------------------------

func _rename(pid:int,name:String)->void:
	var index:=GovernmentPeopleSystem._find_person_index(pid)
	if index<0: return
	GovernmentPeopleSystem.people[index]["name"]=name
	for key in WorldSimulation.state.leadership_positions:
		if int((WorldSimulation.state.leadership_positions[key] as Dictionary).get("person_id",0))==pid: WorldSimulation.state.leadership_positions[key]["name"]=name

func _set_fields(pid:int,fields:Dictionary)->void:
	var index:=GovernmentPeopleSystem._find_person_index(pid)
	for key in fields:
		if key=="empathy": (GovernmentPeopleSystem.people[index]["personality"] as Dictionary)["empathy"]=float(fields[key])
		else: GovernmentPeopleSystem.people[index][key]=fields[key]

func _bonds(pid:int)->Dictionary:
	var person:=GovernmentPeopleSystem.person_snapshot(pid)
	var rel:=Divine.sovereign(person).duplicate()
	rel["love"]=Divine.love_of(person)
	return rel

func _set_bonds(pid:int,values:Dictionary)->void:
	var now:=_bonds(pid)
	var deltas:={}
	for key in values: deltas[key]=float(values[key])-float(now.get(key,0.0))
	GovernmentPeopleSystem.adjust_person_bonds(pid,deltas)

func _cast()->void:
	## The reported court: Catriona Campbell the War Leader, Ansel Reed the
	## Pathfinder, and Zuri Adeyemi; plus whoever else holds office.
	var officials:=Hall._officials()
	var marshal:={}; var scout:={}
	for p:Dictionary in officials:
		if String(p.get("office_key",""))=="Marshal": marshal=p
		if String(p.get("office_key",""))=="ChiefScout": scout=p
	var rest:Array=[]
	for p:Dictionary in officials:
		if p!=marshal and p!=scout: rest.append(p)
	if marshal.is_empty() and not rest.is_empty(): marshal=rest.pop_front()
	if scout.is_empty() and not rest.is_empty(): scout=rest.pop_front()
	if marshal.is_empty() or scout.is_empty() or rest.size()<2: return
	ids["catriona"]=int(marshal.person_id); _rename(ids.catriona,"Catriona Campbell")
	ids["ansel"]=int(scout.person_id); _rename(ids.ansel,"Ansel Reed")
	ids["zuri"]=int((rest[0] as Dictionary).person_id); _rename(ids.zuri,"Zuri Adeyemi")
	ids["other"]=int((rest[1] as Dictionary).person_id)
	# Ordinary, steady servants of the god (no refusal profile).
	for key in ["catriona","ansel","zuri","other"]:
		_set_fields(int(ids[key]),{"courage":0.5,"pride":0.5,"empathy":0.45})
		_set_bonds(int(ids[key]),{"fear":0.12,"resentment":0.05,"love":0.5})
	print("COURT_COMMANDS cast: Catriona=%s (%s), Ansel=%s (%s), Zuri=%s" % [ids.catriona,String(marshal.get("office_title","")),ids.ansel,String(scout.get("office_title","")),ids.zuri])

func _audience_for(pid:int)->Dictionary:
	var modal:Control=director.summon({"person_id":pid})
	if modal==null: return {}
	var id:=String(modal.audience_id)
	await _wait(modal,id,1)
	return {"modal":modal,"id":id}

func _test_classifier()->void:
	var cases:=[["Ansel kill him!","command","kill"],["I DEMAND IT!","command","none"],["Why is the store empty?","question","none"],
		["The rains were late this year.","statement","none"],["Give Zuri 20 food.","command","give"],["Cast out the pathfinder.","command","exile"],
		["Kneel before me, worm.","threat","terrify"],["I bless you for your service.","blessing","bless"],["Strike the war leader down!","command","kill"],
		["Bind him and put him under guard.","command","detain"],["Gather the hunters and double the watch.","command","order"],["Send scouts to the north.","command","send"],
		["Make Zuri our pathfinder.","command","appoint"],["Tell me about the harvest.","question","none"]]
	for c in cases:
		var got:=CC.classify(String(c[0]))
		_check(String(got.act)==String(c[1]) and (String(c[2])=="none" or String(got.verb)==String(c[2])),"classify(%s) gave %s/%s" % [c[0],got.act,got.verb])
	_check(bool(CC.classify("I DEMAND IT!").insist),"insistence not recognised")

func _test_validators()->void:
	var names:Array=["ansel","reed","catriona","campbell"]
	_check(Voice.without_filler("A snapped neck finds no spring; the war leader spoke the hard pebble plain.",names)=="","a stock proverb with no meaning passed")
	_check(Voice.without_filler("A goose may hiss at the fire, but it cannot put it out; I will not kill a loyal voice.",names)=="I will not kill a loyal voice.","a leading proverb clause was not dropped")
	_check(Voice.without_filler("The river is up to the second stone.",names)!="","a plain informative line was rejected")
	_check(Voice.without_filler("No food left in the pits, and I have counted twice.",names)!="","a line with a stance was rejected")
	var refusal:=RegEx.new(); refusal.compile(CC.REFUSAL_PATTERN)
	_check(refusal.search("I will not fight Ansel; if you mean my death, give the order carried by another hand.")!=null,"the reported refusal is not caught")
	_check(Voice.stage_direction("Ansel drives the flint knife into her throat.")=="[Ansel drives the flint knife into her throat.]","stage directions are not bracketed")
	_check(Voice.stage_direction("One. Two. Three. Four five six.")=="","a multi-sentence speech passed as a stage direction")

func _test_screenshot_scene()->void:
	var summon:=await _audience_for(int(ids.catriona))
	if summon.is_empty(): _fail("could not summon Catriona"); return
	var modal:Control=summon.modal; var id:String=summon.id
	var court_ids:Array=Hall.court(id).map(func(p:Dictionary)->int:return int(p.person_id))
	if not int(ids.ansel) in court_ids:
		_fail("Ansel is not at court with Catriona: %s" % str(court_ids)); return
	# The pronoun lands on the one before the god, not on the one ordered.
	var parts:=CC._parties("Ansel kill him!",CC.classify("Ansel kill him!"),Hall.find(id),CC.roster(Hall.find(id)),{})
	_check(int((parts.actor as Dictionary).get("person_id",0))==int(ids.ansel),"'Ansel kill him' did not make Ansel the actor")
	_check(int((parts.target as Dictionary).get("person_id",0))==int(ids.catriona),"'him' did not resolve to Catriona")
	var p2:=CC._parties("Kill her, Ansel!",CC.classify("Kill her, Ansel!"),Hall.find(id),CC.roster(Hall.find(id)),{})
	_check(int((p2.actor as Dictionary).get("person_id",0))==int(ids.ansel) and int((p2.target as Dictionary).get("person_id",0))==int(ids.catriona),"a trailing vocative did not resolve")
	var p3:=CC._parties("Strike the pathfinder down.",CC.classify("Strike the pathfinder down."),Hall.find(id),CC.roster(Hall.find(id)),{})
	_check(int((p3.target as Dictionary).get("person_id",0))==int(ids.ansel) and (p3.actor as Dictionary).is_empty(),"'the pathfinder' did not resolve to Ansel (guards acting)")
	var witnesses:Array=court_ids.filter(func(w:int)->bool:return w!=int(ids.ansel))
	var wbefore:={}
	for w in witnesses: wbefore[int(w)]=_bonds(int(w))
	var legit:=float(GameState.simulation_metrics.get("legitimacy",0.5))
	var ansel_before:=_bonds(int(ids.ansel))
	await _say(modal,id,"Ansel kill him!")
	var dead:=GovernmentPeopleSystem.person_snapshot(int(ids.catriona))
	_check(String(dead.get("status",""))=="deceased","Catriona is not dead after 'Ansel kill him!' (%s)" % String(dead.get("status","")))
	_check(String(Hall.find(id).get("status",""))=="resolved","the audience did not end with her death")
	_check(float(GameState.simulation_metrics.get("legitimacy",0.5))<legit,"the killing cost no legitimacy")
	for w in witnesses: _check(float(_bonds(int(w)).fear)>float(wbefore[int(w)].fear)+0.05,"witness %d dread did not rise" % int(w))
	_check(float(_bonds(int(ids.ansel)).fear)>float(ansel_before.fear),"the executioner's dread did not rise")
	var mem:Array=GovernmentPeopleSystem.person_snapshot(int(ids.ansel)).get("memories",[])
	_check(not mem.is_empty() and "killed Catriona Campbell" in String((mem[0] as Dictionary).get("summary","")),"Ansel has no memory of the killing")
	var lines:Array=Hall.find(id).lines
	var staged:=""; var after_ruler:=false; var ansel_spoke:=false
	for line:Dictionary in lines:
		var text:=String(line.get("text",""))
		if String(line.get("role",""))=="ruler" and text=="Ansel kill him!": after_ruler=true; continue
		if not after_ruler: continue
		if text.begins_with("["): staged=text
		if int(line.get("person_id",0))==int(ids.catriona) or (String(line.get("role",""))=="official" and String(line.get("speaker",""))=="Catriona Campbell"): _fail("the dead spoke: %s" % text)
		if int(line.get("person_id",0))==int(ids.ansel):
			ansel_spoke=true
			var refusal:=RegEx.new(); refusal.compile(CC.REFUSAL_PATTERN)
			_check(refusal.search(text)==null,"Ansel refused in words after obeying: %s" % text)
	_check(staged!="" and "Ansel Reed" in staged and "Catriona Campbell" in staged,"no bracketed stage direction naming both: %s" % staged)
	var metal:=RegEx.new(); metal.compile(METAL_WORDS)
	_check(metal.search(staged)==null,"a stone-age killing used a metal weapon: %s" % staged)
	_check(ansel_spoke,"Ansel did not answer as the one who obeyed")
	_check(modal.find_child("ReceiptHead",true,false)!=null,"no outcome receipt")
	_check(modal.find_child("StageLine",true,false)!=null,"the stage direction is not drawn as a stage line")
	_record(id,"THE REPORTED SCENE: 'Ansel kill him!' before the War Leader")
	modal._close()
	await _frames(2)

func _test_hesitation_then_demand()->void:
	# Zuri loves the god, fears little and is gentle: ordered to kill, she balks once.
	var victim:=int(ids.other)
	_set_fields(int(ids.zuri),{"empathy":0.8})
	_set_bonds(int(ids.zuri),{"love":0.82,"fear":0.08,"resentment":0.02})
	var summon:=await _audience_for(victim)
	var modal:Control=summon.modal; var id:String=summon.id
	var victim_name:=String(GovernmentPeopleSystem.person_snapshot(victim).name)
	if not int(ids.zuri) in Hall.court(id).map(func(p:Dictionary)->int:return int(p.person_id)):
		_fail("Zuri is not at court"); return
	await _say(modal,id,"Zuri, kill %s." % victim_name.get_slice(" ",0))
	_check(String(GovernmentPeopleSystem.person_snapshot(victim).get("status",""))=="active","the loving, gentle Zuri killed without hesitating")
	_check(not (Hall.find(id).get("pending_command",{}) as Dictionary).is_empty(),"no pending order after hesitation")
	var pleaded:=false
	for line:Dictionary in Hall.find(id).lines:
		if int(line.get("person_id",0))==int(ids.zuri): pleaded=true
	_check(pleaded,"Zuri did not plead")
	var res_before:=float(_bonds(int(ids.zuri)).resentment)
	await _say(modal,id,"I DEMAND IT!")
	_check(String(GovernmentPeopleSystem.person_snapshot(victim).get("status",""))=="deceased","'I DEMAND IT!' did not escalate to the killing")
	_check(float(_bonds(int(ids.zuri)).resentment)>res_before+0.03,"a reluctant killing left no wound in Zuri")
	_record(id,"HESITATION, THEN 'I DEMAND IT!'")
	modal._close()
	await _frames(2)

func _test_goods_and_exile()->void:
	var summon:=await _audience_for(int(ids.ansel))
	var modal:Control=summon.modal; var id:String=summon.id
	var food:=Hall.player_stock("Food")
	var zuri_before:=_bonds(int(ids.zuri))
	await _say(modal,id,"Give Zuri 20 food.")
	_check(absf(Hall.player_stock("Food")-(food-20.0))<0.5,"20 food did not leave the stores (%.1f -> %.1f)" % [food,Hall.player_stock("Food")])
	_check(float(_bonds(int(ids.zuri)).obligation)>float(zuri_before.obligation),"the gift did not bind Zuri")
	# After a gift to Zuri, "her" means Zuri.
	var parts:=CC._parties("bless her",CC.classify("Bless her."),Hall.find(id),CC.roster(Hall.find(id)),{})
	_check(int((parts.target as Dictionary).get("person_id",0))==int(ids.zuri),"'her' did not follow the conversation to Zuri")
	await _say(modal,id,"Cast out the pathfinder.")
	_check(String(GovernmentPeopleSystem.person_snapshot(int(ids.ansel)).get("status",""))=="exiled","the pathfinder was not cast out")
	_check(String(Hall.find(id).get("status",""))=="resolved","casting out the one before you did not end the audience")
	_record(id,"GOODS FROM THE STORES, THEN EXILE")
	modal._close()
	await _frames(2)

func _test_orders()->void:
	# A plain order to the local leader goes to the civic pipeline.
	var leader:Dictionary={}
	for p:Dictionary in Hall._officials():
		if String(GovernmentPeopleSystem.person_snapshot(int(p.person_id)).get("local_leader_of",""))!="": leader=p
	if leader.is_empty(): _fail("no settlement leader at court"); return
	var summon:=await _audience_for(int(leader.person_id))
	var modal:Control=summon.modal; var id:String=summon.id
	var before:=(terrain.decrees as Array).size()
	await _say(modal,id,"Gather the hunters and double the watch at night.")
	_check((terrain.decrees as Array).size()>before and "double the watch" in String((terrain.decrees as Array)[-1]),"the settlement leader's order did not reach the civic pipeline: %s" % str(terrain.decrees))
	modal.make_them_wait()
	await _frames(2)
	# Any other order to a central official: the universal custom-directive path.
	var official:=0
	for p:Dictionary in Hall._officials():
		if String(GovernmentPeopleSystem.person_snapshot(int(p.person_id)).get("local_leader_of",""))=="" and String(p.get("office_key",""))!="settlement": official=int(p.person_id); break
	if official==0: _fail("no central official without local duty"); return
	var official_name:=String(GovernmentPeopleSystem.person_snapshot(official).name).get_slice(" ",0)
	summon=await _audience_for(official)
	modal=summon.modal; id=summon.id
	var mods_before:=0
	for m:Dictionary in WorldSimulation.state.active_modifiers:
		if String(m.get("id",""))=="custom_directive": mods_before+=1
	var decrees_before:=(terrain.decrees as Array).size()
	await _say(modal,id,"%s, raise a standing stone to me on the high ridge." % official_name)
	var mods_after:=0
	for m:Dictionary in WorldSimulation.state.active_modifiers:
		if String(m.get("id",""))=="custom_directive": mods_after+=1
	_check(mods_after>mods_before,"an unusual order did not go through the custom-directive path (%d -> %d)" % [mods_before,mods_after])
	_check((terrain.decrees as Array).size()==decrees_before,"the custom order was also sent to the civic pipeline")
	var outcome_seen:=false
	for line:Dictionary in Hall.find(id).lines:
		if String(line.get("role",""))=="narrator" and ("carried out" in String(line.text) or "council" in String(line.text)): outcome_seen=true
	_check(outcome_seen,"no outcome line for the custom order")
	_record(id,"ORDERS: CIVIC PIPELINE AND CUSTOM DIRECTIVE")
	modal.make_them_wait()
	await _frames(2)

func _test_refusal()->void:
	# Dread nearly gone, very brave, proud and embittered: the rare refusal.
	var rebel:=int(ids.zuri)
	_set_fields(rebel,{"courage":0.95,"pride":0.95})
	_set_bonds(rebel,{"fear":0.0,"resentment":0.85,"love":0.2})
	var speaker:=-1
	for p:Dictionary in Hall._officials():
		if int(p.person_id)!=rebel: speaker=int(p.person_id); break
	var summon:=await _audience_for(speaker)
	var modal:Control=summon.modal; var id:String=summon.id
	var name:=String(GovernmentPeopleSystem.person_snapshot(speaker).name).get_slice(" ",0)
	var ob:=CC.obedience(GovernmentPeopleSystem.person_snapshot(rebel),"kill",false,0.5)
	_check(String(ob.id)=="refuse","the rebel profile does not refuse at an even roll: %s" % str(ob))
	await _say(modal,id,"Zuri, kill %s." % name)
	var status:=String(GovernmentPeopleSystem.person_snapshot(rebel).get("status",""))
	var focus:=String((Hall.find(id).get("command_focus",{}) as Dictionary).get("last_ref",""))
	var alive:=String(GovernmentPeopleSystem.person_snapshot(speaker).get("status",""))=="active"
	_check(alive,"the refused order was carried out anyway")
	_check(status=="fled" or focus=="person:%d" % rebel,"a refusal had no consequence (status %s, focus %s)" % [status,focus])
	if status!="fled" and String(Hall.find(id).get("status",""))=="waiting":
		# Seized and kneeling: the god may strike them down.
		await _say(modal,id,"Strike him down.")
		_check(String(GovernmentPeopleSystem.person_snapshot(rebel).get("status",""))=="deceased","the seized rebel could not be struck down")
	_record(id,"THE RARE REFUSAL")
	if String(Hall.find(id).get("status",""))=="waiting": modal.make_them_wait()
	else: modal._close()
	await _frames(2)

func _test_refusal_is_rare()->void:
	var rng:=RandomNumberGenerator.new(); rng.seed=7
	var refused:=0; var n:=2000
	for i in n:
		var courage:=rng.randf_range(0.24,0.92); var pride:=rng.randf_range(0.16,0.88); var suspicion:=rng.randf_range(0.12,0.86)
		var person:={"person_id":1,"courage":courage,"pride":pride,"suspicion":suspicion,"personality":{"empathy":rng.randf()},"traits":[],
			"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"obligation":0.4,"resentment":rng.randf_range(0.0,0.25),"fear":0.04+0.2*(1.0-courage)+0.05*suspicion}}}
		if String(CC.obedience(person,"kill",false,rng.randf()).id)=="refuse": refused+=1
	var share:=float(refused)/float(n)
	print("COURT_COMMANDS refusal share for killing orders across ordinary officials: %.2f%%" % (share*100.0))
	_check(share<0.04,"refusal is not rare: %.3f" % share)
	var frightened:={"person_id":1,"courage":0.95,"pride":0.95,"relationships":{"sovereign":{"fear":0.6,"resentment":0.9}}}
	_check(String(CC.obedience(frightened,"kill",false,0.0).id)!="refuse","a terrified official refused")

func _test_live()->void:
	# A fresh War Leader (Catriona's successor) with Ansel gone: use whoever holds offices now.
	var officials:=Hall._officials()
	if officials.size()<2: _fail("too few officials for the live test"); return
	var speaker:Dictionary=officials[0]
	var actor:Dictionary=officials[1]
	_set_fields(int(actor.person_id),{"courage":0.5,"pride":0.5,"empathy":0.4})
	_set_bonds(int(actor.person_id),{"fear":0.2,"love":0.45,"resentment":0.05})
	_rename(int(actor.person_id),"Tamsin Holt")
	var summon:=await _audience_for(int(speaker.person_id))
	var modal:Control=summon.modal; var id:String=summon.id
	if not int(actor.person_id) in Hall.court(id).map(func(p:Dictionary)->int:return int(p.person_id)): _fail("the live actor is not at court"); return
	var voice:Node=director.voice
	var payloads:Array=[]
	voice.force_offline=false
	voice.config_override={"endpoint":"https://mock.invalid/v1/chat/completions","api_key":"k","model":"mock-model","structured_output":true}
	var speaker_name:=String(speaker.name)
	voice.send_hook=func(aid:String,payload:Dictionary,attempt:int)->void:
		payloads.append(payload)
		var prompt:=String(((payload.messages as Array)[1] as Dictionary).content)
		var content:Dictionary
		if "WHAT ACTUALLY HAPPENED" in prompt:
			var tamsin_key:=""
			for m in voice.scene(aid).officials:
				if int(m.person_id)==int(actor.person_id): tamsin_key=String(m.key)
			content={"lines":[{"speaker_key":"narrator","text":"Tamsin Holt wraps a rawhide cord around %s's throat and pulls until the kicking stops, while the court stares at the embers." % speaker_name,"aside":false},
				{"speaker_key":tamsin_key,"text":"It is done, as you willed it; I will not look away from what I did.","aside":false},
				{"speaker_key":tamsin_key,"text":"A snapped neck finds no spring.","aside":false}],"mood_shift":0.0}
		else:
			content={"lines":[{"speaker_key":"envoy","text":"I will not die by a friend's hand; give the order to another.","aside":false}],"mood_shift":0.0,"divine":"none",
				"command":{"act":"command","verb":"kill","actor_ref":"Tamsin","target_ref":"the one before me","object":"","confidence":0.92}}
		var body:=JSON.stringify({"id":"m","model":"mock-model","choices":[{"finish_reason":"stop","message":{"role":"assistant","content":JSON.stringify(content)}}],"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}})
		voice._on_response.call_deferred(HTTPRequest.RESULT_SUCCESS,200,PackedStringArray(),body.to_utf8_buffer(),aid,attempt)
	var text:="Tamsin, see that this one never draws breath again."
	_check(String(CC.classify(text).verb)=="order","the offline reading of the live test phrase is not just a general order")
	var before:=(Hall.find(id).lines as Array).size()
	modal.speech_input.text=text
	modal._speak()
	await _wait(modal,id,before+3,8.0)
	await _frames(6)
	voice.send_hook=Callable(); voice.config_override={}; voice.force_offline=true
	_check(payloads.size()>=2,"expected a classifying call and a staging call, got %d" % payloads.size())
	if payloads.size()>=1:
		var first:Dictionary=payloads[0]
		var schema:Dictionary=first.get("response_format",{}).get("json_schema",{}).get("schema",{})
		_check((schema.get("properties",{}) as Dictionary).has("command"),"the speak schema has no command field")
		_check("command is law" in String(((first.messages as Array)[0] as Dictionary).content),"the system prompt does not make the god's command law")
	if payloads.size()>=2:
		var second:=String((((payloads[1] as Dictionary).messages as Array)[1] as Dictionary).content)
		_check("OBEYED" in second and "square brackets" in second,"the staging prompt is not told the engine's decision: %s" % second.substr(0,300))
		var keys:Array=(payloads[1] as Dictionary).get("response_format",{}).get("json_schema",{}).get("schema",{}).get("properties",{}).get("lines",{}).get("items",{}).get("properties",{}).get("speaker_key",{}).get("enum",[])
		_check("narrator" in keys,"the staging schema cannot write a stage direction")
	_check(String(GovernmentPeopleSystem.person_snapshot(int(speaker.person_id)).get("status",""))=="deceased","the live-classified order was not carried out")
	var staged:=false; var refused:=false; var filler:=false
	for line:Dictionary in Hall.find(id).lines:
		var t:=String(line.get("text",""))
		if t.begins_with("[Tamsin Holt wraps"): staged=true
		if "give the order to another" in t: refused=true
		if "snapped neck" in t: filler=true
	_check(staged,"the model's stage direction was not used")
	_check(not refused,"the model's provisional refusal reached the transcript")
	_check(not filler,"a meaningless proverb reached the transcript")
	_record(id,"MOCKED LIVE: THE MODEL READS THE ORDER, THE ENGINE DECIDES, THE MODEL STAGES IT")
	modal._close()
	await _frames(2)

func _test_envoy()->void:
	var audience:=Hall.debug_force("gift","rival_b")
	if audience.is_empty(): _fail("no envoy audience could be forced"); return
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait(modal,id,1)
	var civ:=ForeignDiplomacy.civilization("rival_b")
	var opinion:=float((civ.get("player_relation",{}) as Dictionary).get("opinion",0.0))
	var dread:=Divine.civ_dread("rival_b")
	await _say(modal,id,"Guards, kill the envoy.")
	_check(String(Hall.find(id).get("status",""))=="resolved","killing the envoy did not end the audience")
	_check(float((ForeignDiplomacy.civilization("rival_b").get("player_relation",{}) as Dictionary).get("opinion",0.0))<opinion-0.2,"killing an envoy cost no standing with their people")
	_check(Divine.civ_dread("rival_b")>dread,"their people's dread did not rise")
	var envoy_after:=false; var ruled:=false
	for line:Dictionary in Hall.find(id).lines:
		if String(line.get("role",""))=="ruler": ruled=true
		elif ruled and String(line.get("role",""))=="envoy": envoy_after=true
	_check(not envoy_after,"the dead envoy spoke")
	_record(id,"AN ENVOY PUT TO DEATH")
	modal._close()
	await _frames(2)

# ---------------------------------------------------------------------------

func _record(id:String,label:String)->void:
	var audience:=Hall.find(id)
	var block:=PackedStringArray(["","--- %s · %s %s" % [label,String((audience.speaker as Dictionary).get("title","")),String((audience.speaker as Dictionary).get("name",""))]])
	var said:={}
	for line in audience.get("lines",[]):
		var text:=String(line.get("text",""))
		var who:=String(line.get("speaker",""))
		block.append("  %s%s: %s" % [who if who!="" else "(narrator)"," (aside)" if bool(line.get("aside",false)) else "",text])
		if String(line.get("role",""))=="ruler": continue
		var key:=Voice.norm_line(text)
		if said.has(key) and not text.begins_with("[") and String(line.get("role",""))!="narrator": _fail("said twice in one audience: %s" % text)
		said[key]=true
		if not text.begins_with("[") and String(line.get("role",""))!="narrator" and text.split(" ",false).size()>32: _fail("line runs long: %s" % text)
	if String(audience.get("outcome",""))!="": block.append("  Outcome: %s" % String(audience.outcome))
	transcripts.append("\n".join(block))

func _finish()->void:
	for block in transcripts: print(block)
	if failures.is_empty():
		print("COURT_COMMANDS PASS")
		get_tree().quit(0)
	else:
		print("COURT_COMMANDS FAILURES: %d" % failures.size())
		get_tree().quit(1)
