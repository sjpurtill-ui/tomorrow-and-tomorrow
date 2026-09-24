extends Node
## Player-initiated court: the ruler summons an official, the Chief Scout and
## an official with nothing pending. Checks that a summoned person opens with
## their most pressing matter, can raise another, routes spoken orders to the
## civic pipeline, and answers a bare summons briefly. Prints the three
## transcripts.
##   <godot> --headless --path <worktree> res://tests/audience_summon_probe.tscn

const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")
const ModalProbe:=preload("res://tests/audience_modal_probe.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const ScoutProbe:=preload("res://tests/chief_scout_probe.gd")
const Scout:=preload("res://scripts/chief_scout.gd")

var failures:Array[String]=[]
## Nobody talks down to the ruler.
const TALKING_DOWN:="(?i)(\\b(dearie|kiddo|sonny|youngster|little one|my boy|my girl|my pet)\\b|[,:]\\s*child\\b|\\bchild\\s*[,:!?.]*\\s*$|^\\s*child\\b)"
var seen_lines:Dictionary={}
var transcripts:Array[String]=[]

func _fail(text:String)->void:
	failures.append(text); printerr("AUDIENCE_SUMMON FAIL: ",text)

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
	var world:Node=ModalProbe.new()
	world._setup_world()
	world.free()
	var terrain:=ModalProbe.TerrainDouble.new(); terrain.name="TerrainDouble"; add_child(terrain)
	var director:=Director.new(); director.terrain=terrain; add_child(director)
	if "force_offline" in director.voice: director.voice.force_offline=true
	await _frames(2)
	# Nothing from the court arrives on its own.
	GameState.simulation_metrics["food_days"]=6.0; GameState.simulation_metrics["food_intake_ratio"]=0.8
	var arrivals:Array=[]
	for day in range(2,30):
		GameState.elapsed_days=day
		arrivals.append_array(Hall.daily(day))
	if not arrivals.filter(func(a:Dictionary)->bool:return String(a.origin)=="court").is_empty(): _fail("the court came in uninvited")
	var officials:=Hall._officials()
	if officials.size()<2: _fail("need two officials, have %d" % officials.size()); _finish(); return
	var crisis:=Hall.matters().filter(func(m:Dictionary)->bool:return String(m.situation_type)=="crisis_petition")
	if crisis.is_empty(): _fail("the famine left no matter"); _finish(); return
	var steward_id:=int((crisis[0] as Dictionary).holder.person_id)
	var ambition:=Hall._generate_petition(steward_id,int(GameState.elapsed_days),"ambition")
	Hall._file_matter(ambition,[])
	# The dock's list: everyone summonable, with a quiet count.
	var listed:=Hall.summonable()
	var steward_row:={}
	for entry:Dictionary in listed:
		if int((entry.target as Dictionary).get("person_id",0))==steward_id: steward_row=entry
	if steward_row.is_empty() or int(steward_row.matters)<2: _fail("the summon list does not show the steward's two matters: %s" % str(listed))
	await _summon_with_matters(director,terrain,steward_id)
	await _summon_chief_scout(director)
	# The Chief Scout, report delivered, now has nothing pending: a bare summons.
	var idle:={}
	for person:Dictionary in Hall._officials():
		if Hall.matters("person:%d" % int(person.person_id)).is_empty(): idle=person; break
	if idle.is_empty(): _fail("no official without matters to summon")
	else: await _summon_idle(director,int(idle.person_id))
	_finish()

func _scan_banks()->void:
	## No bank anywhere may hand a speaker a condescending address or lead-in.
	var down:=RegEx.new(); down.compile(TALKING_DOWN)
	for path in ["res://scripts/character_voice.gd","res://scripts/audience_voice.gd","res://scripts/chief_scout.gd"]:
		var lines:=FileAccess.get_file_as_string(path).split("\n")
		for index in lines.size():
			var line:=String(lines[index])
			if "never" in line.to_lower() or line.strip_edges().begins_with("#"): continue
			var found:=down.search(line)
			if found!=null and "\"" in line: _fail("%s:%d offers a condescending address (%s)" % [path,index+1,found.get_string()])

func _finish()->void:
	_scan_banks()
	for block in transcripts: print(block)
	if failures.is_empty():
		print("AUDIENCE_SUMMON PASS")
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func _record(id:String,label:String)->void:
	var audience:=Hall.find(id)
	var block:=PackedStringArray(["","--- %s · %s %s (%s)" % [label,String((audience.speaker as Dictionary).get("title","")),String((audience.speaker as Dictionary).get("name","")),String(audience.kind)]])
	for line in audience.get("lines",[]):
		var text:=String(line.get("text",""))
		var who:=String(line.get("speaker",""))
		block.append("  %s%s: %s" % [who if who!="" else "(narrator)"," (aside)" if bool(line.get("aside",false)) else "",text])
		if String(line.get("role",""))=="ruler" or String(line.get("role",""))=="narrator": continue
		var key:=Voice.norm_line(text)
		if seen_lines.has(key): _fail("said twice across summons: %s" % text)
		seen_lines[key]=true
		if text.split(" ",false).size()>32: _fail("summoned line runs long: %s" % text)
		var down:=RegEx.new(); down.compile(TALKING_DOWN)
		if down.search(text)!=null: _fail("someone talked down to the ruler: %s" % text)
	if String(audience.outcome)!="": block.append("  Outcome: %s" % String(audience.outcome))
	transcripts.append("\n".join(block))

func _summon_with_matters(director:Node,terrain:Node,person_id:int)->void:
	var modal:Control=director.summon({"person_id":person_id})
	if modal==null: _fail("summoning the steward opened nothing"); return
	var id:=String(modal.audience_id)
	var audience:=Hall.find(id)
	if String(audience.kind)!="petition" or String((audience.petition as Dictionary).topic)!="food": _fail("the steward did not open with the most pressing matter (%s)" % str(audience.get("petition",{})))
	await _wait(modal,id,1)
	var hear:=Hall.options(id).filter(func(o:Dictionary)->bool:return String(o.id).begins_with("hear:"))
	if hear.is_empty(): _fail("the steward could not raise their other matter")
	# An order given in plain words goes to the civic council.
	var before:int=terrain.decrees.size()
	modal.speech_input.text="Ration food for thirty days."
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	if terrain.decrees.size()!=before+1: _fail("a spoken order was not routed to the civic pipeline")
	var acknowledged:=false
	for line in Hall.find(id).lines:
		for ack in Voice.ORDER_ACK:
			if String(ack).substr(0,14) in String(line.get("text","")): acknowledged=true
	if not acknowledged: _fail("the official did not acknowledge the order")
	# A question is not an order.
	modal.speech_input.text="How long will the stores last?"
	var asked_at:=(Hall.find(id).lines as Array).size()
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	if terrain.decrees.size()!=before+1: _fail("a question was routed as an order")
	var days:=str(int(Hall.voice_context(id).numbers.food_days))
	var told:=false
	for index in range(asked_at,(Hall.find(id).lines as Array).size()):
		var line:Dictionary=Hall.find(id).lines[index]
		if String(line.get("role",""))=="official" and days in String(line.get("text","")): told=true
	if not told: _fail("asked how long the stores last, nobody said %s days" % days)
	_record(id,"SUMMONS 1 (a matter pending, then another)")
	if hear.is_empty(): return
	var result:Dictionary=modal.choose(String(hear[0].id))
	var next_id:=String(result.get("next_audience_id",""))
	if next_id=="" or String(modal.audience_id)!=next_id: _fail("hearing the other matter did not bring it before the ruler"); return
	if Hall.matters("person:%d" % person_id).filter(func(m:Dictionary)->bool:return String(m.situation_type)=="crisis_petition").is_empty(): _fail("the set-aside matter was lost")
	await _wait(modal,next_id,1)
	var decreed:Dictionary=modal.choose("decree")
	if not bool(decreed.get("ok",false)): _fail("the ambition decree failed: %s" % str(decreed))
	await _wait(modal,next_id,(Hall.find(next_id).lines as Array).size()+1)
	_record(next_id,"SUMMONS 1, continued (the other matter)")
	modal._close()
	await _frames(2)

func _summon_chief_scout(director:Node)->void:
	# A real returned party: the report waits as a matter on the Chief Scout.
	var scouts:Node=ScoutProbe.new()
	var event:Dictionary=(scouts._scenarios()[1] as Dictionary).event
	scouts.free()
	var matter:Dictionary=Scout.report_returned(event,"scouts")
	if matter.is_empty() or not Hall.waiting().filter(func(a:Dictionary)->bool:return String(a.kind)=="report").is_empty(): _fail("the scout report did not wait as a matter")
	var modal:Control=director.summon({"role":"chief_scout"})
	if modal==null: _fail("summoning the Chief Scout opened nothing"); return
	var id:=String(modal.audience_id)
	if String(Hall.find(id).kind)!="report": _fail("the Chief Scout did not deliver the pending report"); return
	await _wait(modal,id,1)
	modal.speech_input.text="Would they fight us, if it came to it?"
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	var result:Dictionary=modal.choose("reward_scouts")
	if not bool(result.get("ok",false)): _fail("rewarding the scouts failed")
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	_record(id,"SUMMONS 2 (the Chief Scout, with a report)")
	modal._close()
	await _frames(2)

func _summon_idle(director:Node,person_id:int)->void:
	var modal:Control=director.summon({"person_id":person_id})
	if modal==null: _fail("summoning an idle official opened nothing"); return
	var id:=String(modal.audience_id)
	var audience:=Hall.find(id)
	if String(audience.kind)!="summons": _fail("an official with nothing pending did not simply answer the summons"); return
	var herald:=modal.find_child("HeraldTitle",true,false) as Label
	if herald==null or not "ANSWERS YOUR SUMMONS" in herald.text: _fail("summons herald wrong: %s" % (herald.text if herald else "none"))
	await _wait(modal,id,1)
	var opening:Array=Hall.find(id).lines
	if opening.is_empty(): _fail("the summoned official said nothing")
	modal.speech_input.text="What do the people say about the harvest?"
	modal._speak()
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	var result:Dictionary=modal.choose("dismiss_summons")
	if not bool(result.get("ok",false)): _fail("dismissing the summons failed")
	await _wait(modal,id,(Hall.find(id).lines as Array).size()+1)
	_record(id,"SUMMONS 3 (nothing pending)")
	modal._close()
	await _frames(2)
