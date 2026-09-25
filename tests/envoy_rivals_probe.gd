extends Node
## Envoys with strings, rival rulers as characters (rival_rulers.gd).
##
## Runs the Audience Hall's ten-people world (audience_hall_probe's scenario,
## with its living world repeating every three years) for 25 years under three
## answer policies: "habit" (the transcript probe's ruler: accepts gifts and
## proposals, refuses requests), "random" (any enabled answer) and "heuristic"
## (reads only what the player sees: the tone, a stated cost, a court member's
## objection or support, and the tells of a bluff). Offline voice speaks every
## audience, so the court's objections are heard. Reports and checks:
##   - the share of free gifts (a gift with no cost or string): near zero
##   - every foreign option set shows at least one cost
##   - the distribution of answers per policy ("accept" at most 45%)
##   - distinct rival rulers whose past dealings were recalled in 25 years
##   - grudges that come back within five years; heirs who carry them
##   - bluffs, tells and what calling them did
##   - offline talk with a foreign ruler, and save compatibility
## Writes a transcript of a costly envoy decision and a returning grudge to
## res://reports/audience/envoy_rivals.txt (reports/ is ignored by git).
##   <godot> --headless --path <worktree> res://tests/envoy_rivals_probe.tscn [-- --years=25]

const HALL:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const RIVALS:=preload("res://scripts/rival_rulers.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const CV:=preload("res://scripts/character_voice.gd")
const OUT_PATH:="res://reports/audience/envoy_rivals.txt"
const GIFT_TYPES:=["gift_goods","gratitude_gift","dread_tribute","artifact_gift"]

var probe:Node
var voice:Node
var failures:PackedStringArray=PackedStringArray()
var out:PackedStringArray=PackedStringArray()
var years:=25

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % n): return a.substr(n.length()+3)
	return f

func _ready()->void:
	years=int(_arg("years","25"))
	probe=HallProbe.new()
	voice=Voice.new(); voice.force_offline=true; add_child(voice)
	out.append("ENVOYS WITH STRINGS AND RIVAL RULERS — %d years, ten peoples, offline voice" % years)
	var results:={}
	for policy in ["habit","random","heuristic"]:
		results[policy]=await _run(policy)
	_summary(results)
	_setup()
	_test_offline_talk()
	_setup()
	_test_saves()
	CV.knowledge_override.clear()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/audience/"))
	var file:=FileAccess.open(OUT_PATH,FileAccess.WRITE)
	file.store_string("\n".join(out)+"\n"); file.close()
	print("ENVOY_RIVALS wrote %s" % ProjectSettings.globalize_path(OUT_PATH))
	print("ENVOY_RIVALS "+("PASS" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)

func _setup()->void:
	probe._setup_world()
	HALL.set_frequency("normal")
	var founding:Array=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	CV.knowledge_override["player"]=founding+["clay_shaping","pit_firing","plain_weaving"]
	for civ in CivilizationSystem.civilizations: CV.knowledge_override[String(civ.id)]=founding.duplicate()

func _world(day:int,ids:Array[String],rng:RandomNumberGenerator)->void:
	## The hall probe's three-year living world, repeated with a shift.
	var cycle:=posmod(day,1095)
	if cycle==0: cycle=1095
	if day>1095 and cycle==880:
		for a in ids:
			for b in ids:
				if a!=b: probe._set_war(a,b,false)
		var rel:Dictionary=probe._civ_ref(ids[6]).player_relation
		rel.at_war=false; rel.treaty="none"
	var shifted:Array[String]=ids.duplicate()
	var turn:=floori(float(day-1)/1095.0)
	for i in turn: shifted.push_back(shifted.pop_front())
	probe._world_events(cycle,shifted,rng)

func _pick(audience:Dictionary,policy:String,serial:int,rng:RandomNumberGenerator)->String:
	var enabled:Array=[]
	for option in HALL.options(String(audience.id)):
		if bool(option.enabled): enabled.append(option)
	if enabled.is_empty(): return ""
	match policy:
		"habit": return probe._answer(audience,serial)
		"random": return String(enabled[rng.randi()%enabled.size()].id)
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var tells:Array=situation.get("tells",[]) if situation.get("tells") is Array else []
	var signs:Array=situation.get("signs",[]) if situation.get("signs") is Array else []
	var best:="";var best_score:=-INF
	for o in enabled:
		var score:float={"warm":0.6,"neutral":0.3,"hostile":-0.4}.get(String(o.get("tone","neutral")),0.0)
		var cost_text:=String(o.get("cost",""))
		if cost_text!="":score-=0.7 if cost_text.begins_with("String") else 0.3
		if String(o.get("objection",""))!="":score-=1.0
		if String(o.get("support",""))!="":score+=0.9
		var oid:=String(o.id)
		if not tells.is_empty() and signs.is_empty() and oid in ["defy","counter"]: score+=2.0
		if not tells.is_empty() and signs.is_empty() and oid=="pay": score-=1.0
		score+=rng.randf()*0.3
		if score>best_score: best_score=score; best=oid
	return best

func _run(policy:String)->Dictionary:
	_setup()
	var ids:Array[String]=probe._civ_ids()
	var rng:=RandomNumberGenerator.new(); rng.seed=int(HallProbe.SEED)+policy.hash()
	var pick_rng:=RandomNumberGenerator.new(); pick_rng.seed=4242+policy.hash()
	var r:={"audiences":0,"foreign":0,"gifts":0,"free_gifts":0,"sets":0,"sets_with_cost":0,"objections":0,"objection_spoken":0,"picks":{},"recalled":{},"recalls":0,
		"grudges":[],"grudge_refs":{},"heirs":[],"threats":0,"bluffs":0,"bluff_tells":0,"called":0,"called_bluffs":0,"paid_bluffs":0,"strings":{},"costly":PackedStringArray(),"grudge_story":PackedStringArray(),"first_seen":{}}
	var serial:=0
	var seen_grudges:={}
	var audiences_by_id:={}
	for day in range(1,years*365+1):
		GameState.elapsed_days=day
		probe._refill()
		_world(day,ids,rng)
		for audience in HALL.daily(day):
			serial+=1
			await _play(audience,policy,serial,pick_rng,r,audiences_by_id)
		if day%30==0:
			for id in ids:
				var c:=RIVALS.character(id)
				if c.is_empty(): continue
				for g in c.get("grudges",[]):
					var key:="%s:%d:%s" % [id,int(g.day),String(g.text).left(30)]
					if seen_grudges.has(key) or bool(g.get("inherited",false)): continue
					seen_grudges[key]=true
					(r.grudges as Array).append({"civ":id,"day":int(g.day),"text":String(g.text)})
				if not (c.lineage as Array).is_empty():
					var heir_key:="%s:%d" % [id,int(c.gen)]
					if not (r.heirs as Array).has(heir_key): (r.heirs as Array).append(heir_key)
	# Grudges that came back within five years (recalled by name or as a demand for redress).
	var eligible:=0; var returned:=0
	for g in r.grudges:
		if int(g.day)>years*365-5*365: continue
		eligible+=1
		if (r.grudge_refs as Dictionary).has("%s:%d" % [String(g.civ),int(g.day)]): returned+=1
	r["grudges_eligible"]=eligible; r["grudges_returned"]=returned
	return r

func _play(audience:Dictionary,policy:String,serial:int,rng:RandomNumberGenerator,r:Dictionary,by_id:Dictionary)->void:
	var id:=String(audience.id)
	r.audiences=int(r.audiences)+1
	voice.open_scene(id)
	await get_tree().process_frame
	var a:=HALL.find(id)
	if String(a.get("origin",""))!="foreign":
		var pick0:=_pick(a,"random",serial,rng)
		if pick0!="": HALL.resolve(id,pick0)
		return
	r.foreign=int(r.foreign)+1
	var situation:Dictionary=a.get("situation",{}) if a.get("situation") is Dictionary else {}
	var type:=String(situation.get("type",""))
	var string:Dictionary=situation.get("string",{}) if situation.get("string") is Dictionary else {}
	(r.strings as Dictionary)[String(string.get("type","(none)"))]=int((r.strings as Dictionary).get(String(string.get("type","(none)")),0))+1
	if type in GIFT_TYPES:
		r.gifts=int(r.gifts)+1
		if string.is_empty(): r.free_gifts=int(r.free_gifts)+1
	var options:=HALL.options(id)
	var has_cost:=false
	var objection:={}
	for o in options:
		if String(o.get("cost",""))!="": has_cost=true
		if String(o.get("objection",""))!="": objection=o
	r.sets=int(r.sets)+1
	if has_cost: r.sets_with_cost=int(r.sets_with_cost)+1
	else: check(false,"%s: a foreign option set with no cost line (%s)" % [policy,type])
	var lines:Array=a.get("lines",[])
	if not objection.is_empty():
		r.objections=int(r.objections)+1
		var who:=String(objection.objection).get_slice(" ",0)
		for line in lines:
			if String(line.get("speaker","")).begins_with(who): r.objection_spoken=int(r.objection_spoken)+1; break
	var recall:Dictionary=situation.get("recall",{}) if situation.get("recall") is Dictionary else {}
	if not recall.is_empty():
		r.recalls=int(r.recalls)+1
		(r.recalled as Dictionary)[String(recall.get("ruler",""))]=true
		if String(recall.kind) in ["grudge"]: (r.grudge_refs as Dictionary)["%s:%d" % [String(a.civ_id),int(recall.day)]]=day_of(a)
	if type=="redress_demand": (r.grudge_refs as Dictionary)["%s:%d" % [String(a.civ_id),int(situation.get("grudge_day",-1))]]=day_of(a)
	var hidden:Dictionary=a.get("hidden",{}) if a.get("hidden") is Dictionary else {}
	if String(a.kind)=="threat":
		r.threats=int(r.threats)+1
		if bool(hidden.get("bluff",false)):
			r.bluffs=int(r.bluffs)+1
			if not (situation.get("tells",[]) as Array).is_empty(): r.bluff_tells=int(r.bluff_tells)+1
	var pick:=_pick(a,policy,serial,rng)
	var picks:Dictionary=r.picks
	picks[pick]=int(picks.get(pick,0))+1
	var result:Dictionary={"ok":false,"outcome":"(no enabled option)","reaction":"neutral"}
	if pick!="": result=HALL.resolve(id,pick)
	result["option_id"]=pick
	voice.closing(id,result)
	await get_tree().process_frame
	if String(a.kind)=="threat" and pick in ["defy","counter"]:
		r.called=int(r.called)+1
		if bool(hidden.get("bluff",false)): r.called_bluffs=int(r.called_bluffs)+1
	if String(a.kind)=="threat" and pick=="pay" and bool(hidden.get("bluff",false)): r.paid_bluffs=int(r.paid_bluffs)+1
	var block:=_block(HALL.find(id),options,pick,result)
	by_id[id]=block
	if (r.costly as PackedStringArray).is_empty() and not objection.is_empty() and not string.is_empty() and String(string.type) in ["marriage","debt","hunting","emboldens","feud","secret","sickness"] and policy=="heuristic":
		r.costly=block
	# The story of a grudge that returns: a demand for redress is preferred to a
	# grudge merely named.
	var redress:=type=="redress_demand"
	if policy=="heuristic" and (redress or String(recall.get("kind",""))=="grudge") and ((r.grudge_story as PackedStringArray).is_empty() or (redress and not bool(r.get("story_redress",false)))):
		r["story_redress"]=redress
		var story:=PackedStringArray()
		var gday:=int(recall.get("day",situation.get("grudge_day",-1)))
		story.append("The grudge (day %d): %s" % [gday,String(situation.get("summary",""))])
		for earlier_id in by_id:
			var earlier:Dictionary=HALL.find(String(earlier_id))
			if absi(int(earlier.get("arrived_day",-9))-gday)<=25 and String(earlier_id)!=id:
				story.append("  -- where it began --"); story.append_array(by_id[earlier_id] as PackedStringArray)
				break
		story.append("  -- and %d days later it came back --" % (day_of(a)-gday))
		story.append_array(block)
		r.grudge_story=story

func day_of(a:Dictionary)->int:
	return int(a.get("arrived_day",GameState.elapsed_days))

func _block(a:Dictionary,options:Array,pick:String,result:Dictionary)->PackedStringArray:
	var situation:Dictionary=a.get("situation",{}) if a.get("situation") is Dictionary else {}
	var block:=PackedStringArray()
	block.append("-".repeat(78))
	block.append("Day %d · %s · %s — %s (%s)" % [int(a.get("arrived_day",0)),String(a.kind).to_upper(),String(situation.get("type","")),String(a.get("civ_name","")),String(situation.get("ruler",""))])
	block.append("Facts: %s" % String(situation.get("summary","")))
	for t in situation.get("tells",[]): block.append("Tell: %s" % String(t))
	for t in situation.get("signs",[]): block.append("Sign: %s" % String(t))
	for line in a.get("lines",[]):
		block.append("  %s%s: %s" % [String(line.get("speaker","")) if String(line.get("speaker",""))!="" else "(narrator)"," (aside)" if bool(line.get("aside",false)) else "",String(line.get("text",""))])
	block.append("  Options:")
	for o in options:
		block.append("    [%s] %s — %s%s%s" % [String(o.id),String(o.label),String(o.get("sub","")),("\n        objects: "+String(o.objection)) if String(o.get("objection",""))!="" else "",("\n        for it: "+String(o.support)) if String(o.get("support",""))!="" else ""])
	block.append("  Answer: %s — %s" % [pick,String(result.get("outcome",""))])
	return block

func _summary(results:Dictionary)->void:
	out.append("")
	for policy in results:
		var r:Dictionary=results[policy]
		var picks:Dictionary=r.picks
		var total:=0
		for k in picks: total+=int(picks[k])
		var accepts:=int(picks.get("accept",0))+int(picks.get("accept_return",0))
		var dist:PackedStringArray=PackedStringArray()
		var keys:Array=picks.keys(); keys.sort_custom(func(x:Variant,y:Variant)->bool:return int(picks[x])>int(picks[y]))
		for k in keys: dist.append("%s %d" % [String(k),int(picks[k])])
		var line:="%s: %d audiences (%d foreign). Gifts %d, free %d (%.0f%%). Option sets with a cost %d/%d. Objections %d (spoken %d). Accept %d/%d (%.0f%%). Answers: %s." % [
			policy,int(r.audiences),int(r.foreign),int(r.gifts),int(r.free_gifts),100.0*float(r.free_gifts)/maxf(1.0,float(r.gifts)),int(r.sets_with_cost),int(r.sets),int(r.objections),int(r.objection_spoken),accepts,total,100.0*float(accepts)/maxf(1.0,float(total)),", ".join(dist)]
		out.append(line); print("ENVOY_RIVALS "+line)
		var line2:="%s: rival rulers recalled %d (%s); recalls %d; grudges %d, returned within 5 years %d/%d; heirs %s; threats %d, bluffs %d (tells shown %d), called %d (of them bluffs %d), bluffs paid %d; strings %s" % [
			policy,(r.recalled as Dictionary).size(),", ".join(PackedStringArray((r.recalled as Dictionary).keys())),int(r.recalls),(r.grudges as Array).size(),int(r.grudges_returned),int(r.grudges_eligible),str(r.heirs),int(r.threats),int(r.bluffs),int(r.bluff_tells),int(r.called),int(r.called_bluffs),int(r.paid_bluffs),JSON.stringify(r.strings)]
		out.append(line2); print("ENVOY_RIVALS "+line2)
		check(float(r.free_gifts)<=0.05*maxf(1.0,float(r.gifts)),"%s: free gifts %d of %d" % [policy,int(r.free_gifts),int(r.gifts)])
		if years<10: continue   # a short smoke run: long-run shares are not meaningful
		if policy!="habit": check(float(accepts)<=0.45*float(total),"%s: accept share %d/%d" % [policy,accepts,total])
		check((r.recalled as Dictionary).size()>=3,"%s: only %d rival rulers recalled" % [policy,(r.recalled as Dictionary).size()])
		check(int(r.objection_spoken)>=int(r.objections)/2,"%s: objections rarely spoken (%d of %d)" % [policy,int(r.objection_spoken),int(r.objections)])
		if int(r.grudges_eligible)>0: check(int(r.grudges_returned)>=1,"%s: no grudge came back within five years" % policy)
	var h:Dictionary=results.get("heuristic",{})
	if years>=10: check(not (h.get("heirs",[]) as Array).is_empty(),"No ruler died and was succeeded in %d years" % years)
	out.append("")
	out.append("=".repeat(78)); out.append("A COSTLY ENVOY DECISION (heuristic player)"); out.append("=".repeat(78))
	out.append_array(h.get("costly",PackedStringArray()))
	out.append("")
	out.append("=".repeat(78)); out.append("A GRUDGE THAT RETURNS (heuristic player)"); out.append("=".repeat(78))
	out.append_array(h.get("grudge_story",PackedStringArray()))
	check(not (h.get("costly",PackedStringArray()) as PackedStringArray).is_empty(),"No costly decision with an objection was seen")
	if years>=10: check(not (h.get("grudge_story",PackedStringArray()) as PackedStringArray).is_empty(),"No grudge came back to the hall")
	# Characters: one portrait and one manner for life, distinct across rulers.
	var models:={}
	for civ in CivilizationSystem.civilizations:
		var view:=RIVALS.rival_character(String(civ.id))
		if view.is_empty(): continue
		models[String(view.voice_model)]=int(models.get(String(view.voice_model),0))+1
		out.append("Ruler of %s: %s, %s, age %d, generation %d, manner of %s, portrait %d, %d grudges, %d debts, %d bonds%s" % [String(view.civ_name),String(view.name),String(view.trait_words),int(view.age),int(view.generation),String(view.voice_name),int(view.portrait),(view.grudges as Array).size(),(view.debts as Array).size(),(view.bonds as Array).size(),(" (after %s)" % String((view.lineage[0] as Dictionary).name)) if not (view.lineage as Array).is_empty() else ""])
	for m in models: check(int(models[m])<=2,"Voice manner %s is held by %d rulers" % [String(m),int(models[m])])

func _test_offline_talk()->void:
	var id:=String(CivilizationSystem.civilizations[0].id)
	GameState.elapsed_days=400
	RIVALS.grudge(id,"how you refused our gift of 20 Stone",0.6,"test")
	RIVALS.debt(id,"player","Timber",30.0,200,"the 30 Timber you owe for their gift")
	var choices:=RIVALS.talk_choices(id)
	var ids:Array=choices.map(func(c:Dictionary)->String:return String(c.id))
	check("amends" in ids and "pay_debt" in ids and "ask_intent" in ids and "warn" in ids,"Offline talk choices do not follow the state: %s" % str(ids))
	var persona:=CV.for_foreign_leader(id)
	check(String(persona.get("model",""))==String(RIVALS.character(id).model),"The ruler does not speak in their lifelong manner")
	out.append("")
	out.append("=".repeat(78)); out.append("OFFLINE TALK WITH %s (%s, manner of %s)" % [RIVALS.ruler_name(id),String(RIVALS.rival_character(id).trait_words),String(persona.get("model_name",""))]); out.append("=".repeat(78))
	out.append("Choices: "+", ".join(PackedStringArray(choices.map(func(c:Dictionary)->String:return String(c.label)))))
	for choice_id in ["ask_intent","amends","pay_debt","marriage","warn"]:
		var before:=RIVALS.grudge_weight(id)
		var reply:=RIVALS.talk_reply(id,choice_id)
		check(ForeignDialogue._valid_response(reply,true,"") and ForeignDialogue._reply_stays_in_character(String(reply.reply)),"Offline reply for %s is not a valid in-character answer" % choice_id)
		out.append("  [%s] envoy: %s" % [choice_id,String(reply.envoy_words)])
		out.append("        %s: %s" % [RIVALS.given(id),String(reply.reply)])
		if choice_id=="amends": check(RIVALS.grudge_weight(id)<before,"Amends did not settle a grudge")
	check(RIVALS.open_debt(id,"player").is_empty(),"Paying the debt through the envoy did not settle it")
	# The full journey: brief, travel, return, answer.
	ForeignDiplomacy.leader(id)["audience_day"]=1
	WorldSimulation.world.diplomatic_mission={}
	var sent:=ForeignDialogue.ask_offline(id,"ask_intent")
	out.append("  (journey dispatched: %s; %s)" % [str(sent),String(ForeignDialogue.thread(id).get("status",""))])
	if sent:
		WorldSimulation.world.diplomatic_mission["return_day"]=int(GameState.elapsed_days)
		var back:=WorldSimulation.dialogue.resolve_returned(id)
		check(bool(back.get("ok",false)),"The offline brief came home without an answer: %s" % str(back))
		out.append("  returned: %s" % String(back.get("message","")))
		WorldSimulation.world.diplomatic_mission={}

func _test_saves()->void:
	var id:=String(CivilizationSystem.civilizations[1].id)
	GameState.elapsed_days=10
	var c:=RIVALS.character(id)
	check(not c.is_empty(),"No character for a contacted ruler")
	RIVALS.grudge(id,"how you rebuffed their envoy",0.5,"save")
	RIVALS.bond(id,"marriage","the marriage of Tam into your people")
	var saved:=ForeignDiplomacy.export_state()
	var model:=String(c.model); var portrait:=int(c.portrait)
	var loaded:=ForeignDiplomacy.import_state(saved.duplicate(true))
	check(bool(loaded.get("ok",false)),"Save with rival characters did not load: %s" % str(loaded))
	var again:=RIVALS.character(id)
	check(String(again.model)==model and int(again.portrait)==portrait and RIVALS.grudge_weight(id)>0.4 and not RIVALS.has_bond(id,["marriage"]).is_empty(),"Rival character did not survive a save")
	# An older save: leaders without characters load, and characters appear lazily.
	var old:Dictionary=saved.duplicate(true)
	for key in old.leaders: (old.leaders[key] as Dictionary).erase("character")
	var loaded_old:=ForeignDiplomacy.import_state(old)
	check(bool(loaded_old.get("ok",false)),"An older save without characters did not load")
	check(not RIVALS.character(id).is_empty(),"A character was not created for an older save's ruler")
	# A malformed character is refused.
	var bad:Dictionary=saved.duplicate(true)
	(bad.leaders[id] as Dictionary)["character"]={"gen":"x"}
	check(ForeignDiplomacy.import_state(bad).has("error"),"A malformed character was accepted")
	# The heir: succession keeps the reputation and changes name, manner and picture.
	ForeignDiplomacy.import_state(saved.duplicate(true))
	var before_name:=RIVALS.ruler_name(id)
	var before_model:=String(RIVALS.character(id).model)
	RIVALS.character(id)["dies"]=20
	GameState.elapsed_days=20
	RIVALS.daily(20)
	var heir:=RIVALS.rival_character(id)
	check(String(heir.name)!=before_name and int(heir.generation)==2,"No heir took over")
	check(String(heir.voice_model)!=before_model,"The heir kept the parent's manner")
	check(float(heir.grudge_weight)>0.2 and not (heir.bonds as Array).is_empty(),"The heir did not inherit the parent's reputation")
	check(String((heir.lineage[0] as Dictionary).name)==before_name,"The heir's lineage does not name the parent")
	out.append("")
	out.append("Succession: %s died; %s rules (manner of %s), remembering %s." % [before_name,String(heir.name),String(heir.voice_name),str((heir.grudges as Array).map(func(g:Dictionary)->String:return String(g.text)))])
