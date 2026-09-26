extends Node
## Replays a save's Chronicle through the current Chronicle code, read-only.
##
## The feed stored in a save is what the Chronicle said when it was played.
## This retells the same raw lines, oldest first, through today's shaping and
## year entries, so a change to the telling can be measured on a real
## campaign without playing it again. Nothing is written to the save.
##
##   CHRONICLE_REPLAY_SAVE  path of a COPY of a .save file (TTWORLD2)
##   CHRONICLE_REPLAY_OUT   where to write the replayed feed as JSON
##
## Run: <godot> --headless --path . res://tools/chronicle_replay.tscn
## Measure: python tools/chronicle_repetition.py <out.json>
const Chronicle:=preload("res://scripts/chronicle.gd")
const Annals:=preload("res://scripts/chronicle_annals.gd")

func _ready()->void:call_deferred("run")


func run()->void:
	var path:=OS.get_environment("CHRONICLE_REPLAY_SAVE")
	var out:=OS.get_environment("CHRONICLE_REPLAY_OUT")
	if path=="" or out=="" or not FileAccess.file_exists(path):
		push_error("CHRONICLE_REPLAY_SAVE / CHRONICLE_REPLAY_OUT not set");get_tree().quit(2);return
	var file:=FileAccess.open(path,FileAccess.READ)
	var header:=file.get_line()
	var payload:Variant=bytes_to_var(file.get_buffer(file.get_length()-file.get_position())) if header=="TTWORLD2" else null
	file.close()
	if not payload is Dictionary:
		push_error("unreadable save");get_tree().quit(2);return
	var gs:Dictionary=(payload as Dictionary).get("reflected_GameState",{})
	var source:Dictionary=gs.get("chronicle",{})
	var names:={}
	for d in gs.get("discovery_log",[]):
		if d is Dictionary:names[String(d.get("id",""))]=String(d.get("name",""))
	var end_day:=int(float(gs.get("elapsed_days",0.0)))
	WorldSimulation.clear()
	GameState.reset_for_new_world(int(gs.get("world_seed",1)))
	GameState.settlement_founded_day=0
	GameState.settlement_name=String(gs.get("settlement_name",""))
	# What the people learned, so the year's telling can say what changed.
	GameState.discovery_log.clear()
	for d in gs.get("discovery_log",[]):if d is Dictionary:GameState.discovery_log.append(d)
	GameState.known_discoveries.clear()
	_learned_order=GameState.discovery_log.duplicate()
	_learned_order.sort_custom(func(x:Dictionary,z:Dictionary)->bool:return int(x.get("day",0))<int(z.get("day",0)))
	ForeignDiplomacy.ensure()
	Chronicle.pending_cards.clear()
	GameState.chronicle={}
	var raw:Array=(source.get("entries",[]) as Array).duplicate(true)
	raw.reverse()
	var order:Array=[]
	for i in raw.size():order.append([int((raw[i] as Dictionary).get("day",0)),i])
	order.sort()
	var souls:=RegEx.create_from_string("(\\d+) souls at the hearths")
	GameState.elapsed_days=0.0
	Annals.roll(Chronicle.data(),0)
	for pair in order:
		var e:Dictionary=raw[int(pair[1])]
		var day:=int(e.get("day",0))
		if String(e.get("kind",""))=="annal":continue
		_advance(day)
		var key:=String(e.get("key",""))
		if String(e.get("kind",""))=="hearth_count":
			var t:=String(e.get("text",""))
			var m:=souls.search(t)
			if m!=null:GameState.population_total=int(m.get_string(1))
			Annals.note_tally(Chronicle.data(),{"day":day,"born":_count_before(t,"born"),"buried":_count_before(t,"buried")})
		if key.begins_with("learned:"):
			for id in e.get("learned",[]):Annals.note_learned(Chronicle.data(),String(names.get(String(id),String(id))),day)
		var moment:={"key":key,"day":day,"title":String(e.get("title","")),"text":String(e.get("text","")),"tier":String(e.get("tier","notice")),"kind":String(e.get("kind","story")),"domain":String(e.get("domain",""))}
		# A party's return is retold the way the ledger scan tells it now.
		var ledger_title:=key.get_slice("|",2) if key.begins_with("ev|") else ""
		if ledger_title in ["SCOUTS RETURN","RECRUITMENT PARTY RETURNS"]:
			var told:Array=Chronicle._retell({"title":ledger_title,"description":String(e.get("text",""))})
			moment.title=String(told[0]);moment.text=String(told[1])
			if told.size()>2 and bool(told[2]):moment.tier="whisper"
		if key.begins_with("first:") or key.begins_with("beat:"):moment["first"]=true
		if key.begins_with("crisis:") and key.ends_with(":onset"):moment["priority"]=true
		Chronicle.record(moment)
	_advance(end_day)
	var c:=Chronicle.data()
	print("CHRONICLE REPLAY FLAGS %d" % _flags.size())
	var dump:={"end_day":end_day,"entries":c.get("entries",[]),"annals":c.get("annals",[]),"flags":_flags}
	var o:=FileAccess.open(out,FileAccess.WRITE)
	o.store_string(JSON.stringify(dump))
	o.close()
	print("CHRONICLE REPLAY DONE %d entries" % (c.get("entries",[]) as Array).size())
	get_tree().quit(0)


var _learned_order:Array=[]
var _learned_at:=0


func _advance(day:int)->void:
	GameState.elapsed_days=float(day)
	# The people know what they had learned by that day (era wording).
	while _learned_at<_learned_order.size() and int((_learned_order[_learned_at] as Dictionary).get("day",0))<=day:
		var id:=String((_learned_order[_learned_at] as Dictionary).get("id",""))
		if id!="" and not GameState.known_discoveries.has(id):GameState.known_discoveries.append(id)
		_learned_at+=1
	for year in Annals.roll(Chronicle.data(),day):
		var told:=Chronicle.record(year)
		if not told.is_empty():_check(told)


## Year entries the plain-speech and era checks would object to, judged by
## what the people knew when the year was told.
var _flags:Array=[]
func _check(e:Dictionary)->void:
	var plain:=preload("res://scripts/plain_speech.gd")
	var voice:=preload("res://scripts/character_voice.gd")
	var t:=String(e.get("text",""))+" "+String(e.get("title",""))
	if plain.is_maxim(t):_flags.append({"key":String(e.key),"why":"maxim","text":t})
	var technical:=String(preload("res://scripts/chronicle_years.gd").technical(t))
	if technical!="":_flags.append({"key":String(e.key),"why":"technical","word":technical,"text":t})
	var tags:=voice.era_tags("player")
	for tag in voice.ERA_GATES:
		if tags.has(tag):continue
		var m:RegExMatch=voice._gate_re(tag).search(t)
		if m!=null:_flags.append({"key":String(e.key),"why":"era:"+String(tag),"word":m.get_string(),"text":t})


static func _count_before(text:String,word:String)->int:
	var m:=RegEx.create_from_string("(\\w+) %s" % word).search(text.to_lower())
	if m==null:return 0
	var w:=m.get_string(1)
	if w.is_valid_int():return int(w)
	return maxi(0,Annals.NUMBER_WORDS.find(w))
