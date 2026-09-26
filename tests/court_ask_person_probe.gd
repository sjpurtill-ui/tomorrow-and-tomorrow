extends Node
## "Who is the smartest and most fertile man in the settlement?" asked of a
## summoned official: they answer in character with a real, named person
## (created and remembered), "summon him" brings that same person, and no
## typed words in the Court ever end in "That cannot be done". Offline and
## with a mocked live voice (which maps the words to an off-target action).
##   <godot> --headless --path <worktree> res://tests/court_ask_person_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const Plain:=preload("res://scripts/plain_speech.gd")
const Store:=preload("res://scripts/interaction_store.gd")
const Mode:=preload("res://scripts/ai_mode.gd")

const QUESTION:="Who is the smartest and most fertile man in the settlement?"
const DEAD_ENDS:=["cannot be done","not possible here","unknown command","unknown action"]
const ODD:=["Who is the strongest man in the camp?","Which woman is the most beautiful?","Who is our best hunter?","Who is the oldest?",
	"Who is the laziest fellow here?","Is there a brave man among the fishers?","Who is the most stubborn woman at the fire?","What is the meaning of the stars?",
	"Sing me something.","Exalt him.","Where were you?","Swear it before me.","Pardon her.","You are lying.","Bring the ledger.",
	"Make it rain fish.","Summon the tallest man.","Why is the sky the colour it is?","Tell me about the potters.","Fetch me Zorblax."]

var failures:Array[String]=[]
var director:Node
var terrain:Node

func _fail(text:String)->void:
	failures.append(text); printerr("ASK_PERSON FAIL: ",text)

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
	Mode.reset_for_tests("user://court_ask_person_ai.cfg")
	Store.configure_for_tests("user://court_ask_person_db_%d/" % Time.get_ticks_usec(),"res://tests/__no_shipped_interactions__/")
	terrain=ModalProbe.TerrainDouble.new(); terrain.name="TerrainDouble"; add_child(terrain)
	director=Director.new(); director.terrain=terrain; add_child(director)
	if "force_offline" in director.voice: director.voice.force_offline=true
	await _frames(2)
	GameState.elapsed_days=40
	if Hall._officials().is_empty(): _fail("no officials"); _finish(); return
	_test_parsing()
	_test_tics()
	await _test_offline()
	await _test_online()
	await _test_odd_inputs()
	_finish()

func _official()->Dictionary:
	return Hall._officials()[0]

func _summon_official()->Control:
	var modal:Control=director.summon({"person_id":int(_official().person_id)})
	await _settle(modal)
	return modal

func _all_text(node:Node)->String:
	var parts:PackedStringArray=PackedStringArray()
	if node is Label: parts.append((node as Label).text)
	for c in node.get_children(): parts.append(_all_text(c))
	return "\n".join(parts)

func _lines(id:String)->String:
	var parts:PackedStringArray=PackedStringArray()
	for line:Dictionary in Hall.find(id).get("lines",[]): parts.append("%s: %s" % [String(line.get("speaker","")),String(line.get("text",""))])
	return "\n".join(parts)

func _dead_end(text:String)->String:
	for w in DEAD_ENDS:
		if w in text.to_lower(): return w
	return ""

func _test_parsing()->void:
	var d:=Persons.people_question(QUESTION)
	_check(String(d.get("sex",""))=="male","the question's man was not read: %s" % str(d))
	_check("fertile" in String(d.get("quality","")) and "wit" in String(d.get("quality","")),"smartest and most fertile were not both read: %s" % str(d))
	_check(Persons.people_question("Who is responsible for this?").is_empty(),"a blame question was read as a superlative")
	_check(Persons.people_question("Hold the ford.").is_empty(),"an order was read as a question about people")
	_check(String(Persons.people_question("Who is our best hunter?").get("quality",""))=="best hunter","best hunter not read")
	_check(Persons.typed_action("bring him bread").is_empty(),"'bring him bread' read as a summons")

func _test_tics()->void:
	var t:=Plain.strip_tics("You sent for me, and I have come; strictly speaking, I bring no petition.")
	_check(not "strictly" in t.to_lower() and t.begins_with("You sent for me"),"tic not stripped: %s" % t)
	_check(Plain.strip_tics("Strictly speaking, the stores are low.")=="The stores are low.","leading tic not stripped: %s" % Plain.strip_tics("Strictly speaking, the stores are low."))

func _ask_and_summon(label:String,modal:Control)->void:
	var id:String=modal.audience_id
	var focus_before:Dictionary=(Persons.state().focus.get("person",{}) as Dictionary).duplicate()
	modal.speech_input.text=QUESTION
	modal._speak()
	for i in 20:
		await _frames(1)
		var f:Dictionary=Persons.state().focus.get("person",{})
		if not f.is_empty() and not Persons.same_ref(f,focus_before): break
	await _settle(modal)
	var ref:Dictionary=Persons.state().focus.get("person",{})
	var p:=Persons.by_id(String(ref.get("id","")))
	_check(not p.is_empty() and not Persons.same_ref(ref,focus_before),"%s: no person was named" % label)
	if p.is_empty(): print(_lines(id)); return
	var said:=_lines(id)
	_check(String(p.given) in said,"%s: the official did not name %s:\n%s" % [label,String(p.name),said])
	_check(String(p.sex)=="male" and int((p.household as Dictionary).children)>=7,"%s: not a fertile man: %s" % [label,str(Persons.view(p))])
	_check(_dead_end(said+_all_text(modal))=="","%s: a dead end was shown:\n%s" % [label,said])
	print("ASK_PERSON %s answer:\n%s" % [label,said])
	# "summon him" brings exactly that person.
	modal.speech_input.text="Summon him."
	modal._speak()
	for i in 20:
		await _frames(1)
		if String(modal.audience_id)!=id: break
	await _settle(modal)
	var here:=Hall.find(String(modal.audience_id))
	_check(String((here.get("speaker",{}) as Dictionary).get("known_id",""))==String(p.id),"%s: 'summon him' did not bring %s (speaker %s)" % [label,String(p.name),str(here.get("speaker",{}))])
	print("ASK_PERSON %s summoned:\n%s" % [label,_lines(String(modal.audience_id))])
	# Asking again names the same person (persisted).
	_check(Persons.resolve(Persons.people_question(QUESTION)).get("ref",{}).get("id","")==String(p.id),"%s: asking again named someone else" % label)
	modal._close(); await _frames(2)

func _test_offline()->void:
	var modal:=await _summon_official()
	await _ask_and_summon("offline",modal)

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

func _test_online()->void:
	# Forget the offline answer so the live path must name someone new.
	(Persons.state().people as Array).clear()
	Persons.state().focus.erase("person")
	var voice:Node=director.voice
	var payloads:Array=[]
	# The live model maps the question to an off-target judgment (the
	# playtest's dead end) and invents a name; then maps "summon him" to talk.
	_mock(voice,func(_aid:String,payload:Dictionary)->Dictionary:
		var summon:="Summon him" in JSON.stringify(payload)
		if summon: return {"canonical_action":"talk","choice":-1,"label":"","deltas":[],"lines":[{"speaker_key":"envoy","text":"I will send for him.","aside":false}],"reply_template":"","generalizable":false,"mood_shift":0.0}
		return {"canonical_action":"novel:name_the_wisest","choice":-1,"label":"Name the wisest","deltas":[],"lines":[{"speaker_key":"envoy","text":"That would be Zorbu the flint-knapper, Great One.","aside":false}],"reply_template":"","generalizable":false,"mood_shift":0.0},payloads)
	var modal:=await _summon_official()
	await _ask_and_summon("online",modal)
	_unmock(voice)
	_check(payloads.size()>=1,"the live voice was never asked")
	# The stilted summons greeting: the live opening is told to hand the floor back plainly.
	var instr:String=voice._stage_instruction({"kind":"summons","origin":"court","officials":[],"arc":{},"occasion":{}},"open",{})
	_check("ONE short, plain line" in instr and not "self-interest" in instr,"the summons opening still asks for a petition: %s" % instr)

func _test_odd_inputs()->void:
	for offline in [true,false]:
		var voice:Node=director.voice
		var payloads:Array=[]
		if not offline:
			_mock(voice,func(_aid:String,_payload:Dictionary)->Dictionary:
				return {"canonical_action":"novel:do_the_odd_thing","choice":-1,"label":"Do the odd thing","deltas":[],"lines":[{"speaker_key":"envoy","text":"As you say, Great One.","aside":false}],"reply_template":"","generalizable":false,"mood_shift":0.0},payloads)
		var modal:=await _summon_official()
		for text in ODD:
			if not is_instance_valid(modal) or not modal.resolved_result.is_empty() or modal.mode!="audience":
				modal=await _summon_official()
			modal.speech_input.text=text
			modal._speak()
			await _frames(4)
			await _settle(modal)
			var seen:=_lines(String(modal.audience_id))+"\n"+_all_text(modal)
			var bad:=_dead_end(seen)
			_check(bad=="","%s '%s' ended in '%s'" % ["offline" if offline else "online",text,bad])
		if not offline: _unmock(voice)
		print("ASK_PERSON odd inputs %s: last transcript\n%s" % ["offline" if offline else "online",_lines(String(modal.audience_id))])
		modal._close(); await _frames(2)

func _finish()->void:
	if failures.is_empty():
		print("ASK_PERSON PASS")
		get_tree().quit(0)
	else:
		print("ASK_PERSON FAILURES: %d" % failures.size())
		get_tree().quit(1)
