extends Node
## Reading harness and quality gate: runs the Audience Hall's three-year
## "normal" world (audience_hall_probe's scenario) in a stone-age world with a
## full court, plays every audience offline (opening, one ruler line, an answer,
## farewell) and writes the whole transcript to
## res://reports/audience/transcript_3yr.txt (reports/ is ignored by git).
## A second section continues the same world a year later in an age that knows
## metal, fermentation and writing. Exits 1 if the transcript breaks a rule:
## any line said twice, a person changing manner or address term, the address
## in more than one line in three, unanswered questions, officials speaking
## outside their manner, long audiences, or modern office titles in the stone age.
##   <godot> --headless --path <worktree> res://tests/audience_transcript_dump.tscn

const HALL:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const Voice:=preload("res://scripts/audience_voice.gd")
const CV:=preload("res://scripts/character_voice.gd")
const OUT_PATH:="res://reports/audience/transcript_3yr.txt"
const LATER_IDS:=["copper_smelting","bronze_alloying","bloomery_smelting","fermentation_control","pictographic_records","phonetic_notation"]
const MODERN_TITLE:="(?i)(secretary|federal|mayor|minister|convenor|delegate|councillor|prefect|chancellor|director|governor)"
const RULER_LINES:={
	"gift":["And what does your chief hope this buys?","You are generous. Why now?","And if we say no?","What do you gain from this?","Why bring it to us?","We accept kindness, but we remember debts."],
	"request":["Why should my people go hungry for yours?","How long will your need last?","What would you give in return?","And if we say no?","Why now?","What do you need, exactly?"],
	"threat":["And if we refuse?","Why should we pay?","What do you gain from threatening us?","Why now?","Your chief is bold for someone so far away."],
	"news":["How do you know this?","Why bring it to us?","Who else has heard it?","How sure are you?"],
	"proposal":["What does your people gain from this?","And if we say no?","Who keeps the peace if one of us breaks it?","Why now?","What do you need from us today?"],
	"petition":["Tell me plainly what you need.","Why has this not been solved already?","Who else supports you in this?","And if I say no?","Why now?"],
	"report":["Would they fight us, if it came to it?","What surprised you most?","How sure are you?","Why bring this to me now?"],
}

var probe:Node
var voice:Node
var out:PackedStringArray=PackedStringArray()
var audiences:=0
var spoken_lines:=0
var per_audience:Array[int]=[]
var failures:PackedStringArray=PackedStringArray()
var samples:Array[PackedStringArray]=[]
var seen_text:Dictionary={}        # normalized line -> first "day speaker"
var duplicates:=0
var models_by_person:Dictionary={} # speaker -> {model:true}
var address_lines:Dictionary={}    # speaker -> [lines, lines with an address term, {terms}]
var questions:=0
var answered:=0
var words_total:=0
var words_short:=0

func _ready()->void:
	probe=HallProbe.new()
	probe._setup_world()
	voice=Voice.new(); voice.force_offline=true; add_child(voice)
	var founding:Array=preload("res://scripts/founding_knowledge.gd").PRACTICES.duplicate()
	_set_knowledge(founding)
	var ids:Array[String]=probe._civ_ids()
	HALL.set_frequency("normal")
	out.append("AUDIENCE HALL TRANSCRIPT — three years, frequency normal, offline voice")
	out.append("World: %d peoples, court of %d officials. Era: %s" % [ids.size(),HALL._officials().size(),CV.ERA_WORDS[CV.era_tier(CV.era_tags("player"))]])
	out.append("Court: "+_court_line())
	var modern:=RegEx.new(); modern.compile(MODERN_TITLE)
	for office in GovernmentPeopleSystem.active_offices():
		if modern.search(String(office.title))!=null: failures.append("stone-age office title reads modern: %s" % office.title)
	out.append("")
	out.append("=".repeat(78))
	out.append("SECTION 1 — STONE AGE, DAYS 1-%d" % (int(probe.YEARS)*365))
	out.append("=".repeat(78))
	var rng:=RandomNumberGenerator.new(); rng.seed=int(probe.SEED)
	for day in range(1,int(probe.YEARS)*365+1):
		await _day(day,ids,rng)
	var first_section:int=audiences
	# A year later, in an age of metal, fermentation and writing.
	var later:Array=founding.duplicate(); later.append_array(LATER_IDS)
	_set_knowledge(later)
	out.append("")
	out.append("=".repeat(78))
	out.append("SECTION 2 — ONE YEAR LATER. Era: %s" % CV.ERA_WORDS[CV.era_tier(CV.era_tags("player"))])
	out.append("Court: "+_court_line())
	out.append("=".repeat(78))
	var start:int=int(probe.YEARS)*365+365
	for day in range(start,start+900):
		if audiences-first_section>=5: break
		await _day(day,ids,rng)
	_score()
	out.append("")
	out.append("TOTAL: %d audiences (%d in section 1, %d in section 2), %d spoken lines." % [audiences,first_section,audiences-first_section,spoken_lines])
	out.append("Lines per audience (without the ruler): %s" % ", ".join(PackedStringArray(per_audience.map(func(n:int)->String: return str(n)))))
	out.append("Duplicate lines: %d. Questions answered from the facts: %d of %d. Lines of 20 words or fewer: %d of %d." % [duplicates,answered,questions,words_short,words_total])
	for failure in failures: out.append("RULE BROKEN: "+failure)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/audience/"))
	var file:=FileAccess.open(OUT_PATH,FileAccess.WRITE)
	file.store_string("\n".join(out)+"\n")
	file.close()
	print("AUDIENCE_TRANSCRIPT wrote %s: %d audiences (%d + %d), %d lines, per audience %s" % [ProjectSettings.globalize_path(OUT_PATH),audiences,first_section,audiences-first_section,spoken_lines,str(per_audience)])
	print("AUDIENCE_TRANSCRIPT duplicates=%d questions answered %d/%d short lines %d/%d" % [duplicates,answered,questions,words_short,words_total])
	for sample in samples: print("\n".join(sample))
	CV.knowledge_override.clear()
	if failures.is_empty(): print("AUDIENCE_TRANSCRIPT PASS")
	else:
		for failure in failures: printerr("AUDIENCE_TRANSCRIPT FAIL: ",failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func _court_line()->String:
	var names:PackedStringArray=PackedStringArray()
	for p:Dictionary in HALL._officials(): names.append("%s (%s)" % [String(p.name),String(p.get("office_title",p.get("office_key","")))])
	return ", ".join(names)

func _set_knowledge(ids:Array)->void:
	CV.knowledge_override["player"]=ids.duplicate()
	for civ in CivilizationSystem.civilizations: CV.knowledge_override[String(civ.id)]=ids.duplicate()

func _day(day:int,ids:Array[String],rng:RandomNumberGenerator)->void:
	GameState.elapsed_days=day
	probe._refill()
	if day<=int(probe.YEARS)*365: probe._world_events(day,ids,rng)
	for audience in HALL.daily(day):
		await _play(audience)

func _play(audience:Dictionary)->void:
	var id:=String(audience.id)
	var kind:=String(audience.kind)
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	audiences+=1
	var s:Dictionary=voice.scene(id)
	var models:={}
	for member in [s.envoy]+(s.officials as Array): models[String(member.name)]=String(member.persona.get("model_name",""))
	voice.open_scene(id)
	var lines_bank:Array=RULER_LINES.get(kind,RULER_LINES.petition)
	var ruler_line:=String(lines_bank[(audiences*7+int(audience.arrived_day))%lines_bank.size()])
	voice.player_speaks(id,ruler_line)
	if not voice.question_type(ruler_line).is_empty() and not voice.answer_bank(s,ruler_line).is_empty():
		questions+=1
		if bool(voice.answered.get(id,false)): answered+=1
	var option:String=probe._answer(audience,audiences)
	var result:Dictionary={"ok":false,"outcome":"(no enabled option)","reaction":"neutral"}
	if option!="": result=HALL.resolve(id,option)
	result["option_id"]=option
	voice.closing(id,result)
	await get_tree().process_frame
	var speaker:Dictionary=audience.get("speaker",{})
	var who:=String(audience.get("civ_name","")) if String(audience.get("origin",""))=="foreign" else "%s %s" % [String(speaker.get("title","")),String(speaker.get("name",""))]
	var block:=PackedStringArray()
	block.append("-".repeat(78))
	block.append("Day %d · %s · %s — %s %s" % [int(audience.arrived_day),kind.to_upper(),String(situation.get("type",kind)),who.strip_edges(),String(situation.get("headline",""))])
	var occasion:Dictionary=situation.get("occasion",{}) if situation.get("occasion") is Dictionary else {}
	if not String(occasion.get("text","")).is_empty(): block.append("Occasion: %s%s" % [String(occasion.text)," (crisis)" if bool(occasion.get("crisis",false)) else ""])
	var arc:Dictionary=situation.get("arc",{}) if situation.get("arc") is Dictionary else {}
	if not arc.is_empty(): block.append("Arc: %s after %s" % [String(arc.get("branch","")),JSON.stringify(arc.get("previous",{}))])
	if not String(situation.get("summary","")).is_empty(): block.append("Facts: %s" % String(situation.summary))
	block.append("")
	var count:=0
	for line in HALL.find(id).get("lines",[]):
		var name:=String(line.get("speaker",""))
		var text:=String(line.get("text",""))
		var ruler:=String(line.get("role",""))=="ruler"
		var manner:=String(models.get(name,""))
		var tag:=" [%s]" % manner if not manner.is_empty() and not ruler else ""
		block.append("  %s%s%s: %s" % [name if not name.is_empty() else "(narrator)",tag," (aside)" if bool(line.get("aside",false)) else "",text])
		if ruler: continue
		count+=1; spoken_lines+=1
		_check_line(name,manner,text,int(audience.arrived_day))
	per_audience.append(count)
	if count>9: failures.append("day %d audience ran to %d lines" % [int(audience.arrived_day),count])
	block.append("")
	block.append("  Answer: %s — %s" % [option,String(result.get("outcome",""))])
	out.append("")
	out.append_array(block)
	if samples.size()<3 and audiences in [2,6,11]: samples.append(block)

func _check_line(speaker:String,manner:String,text:String,day:int)->void:
	var key:=Voice.norm_line(text)
	if seen_text.has(key):
		duplicates+=1
		failures.append("said twice (%s, then day %d %s): %s" % [String(seen_text[key]),day,speaker,text])
	else: seen_text[key]="day %d %s" % [day,speaker]
	if not manner.is_empty():
		var held:Dictionary=models_by_person.get(speaker,{})
		held[manner]=true; models_by_person[speaker]=held
	var tally:Array=address_lines.get(speaker,[0,0,{}])
	tally[0]=int(tally[0])+1
	for d in CV.DIALECTS:
		for term in d.address:
			if String(term) in text: tally[1]=int(tally[1])+1; (tally[2] as Dictionary)[String(term)]=true; break
	address_lines[speaker]=tally
	var words:=text.split(" ",false).size()
	words_total+=1
	if words<=20: words_short+=1

func _score()->void:
	for speaker in models_by_person:
		if (models_by_person[speaker] as Dictionary).size()>1: failures.append("%s changed manner: %s" % [speaker,", ".join(PackedStringArray((models_by_person[speaker] as Dictionary).keys()))])
	for speaker in address_lines:
		var tally:Array=address_lines[speaker]
		if (tally[2] as Dictionary).size()>1: failures.append("%s addresses the ruler several ways: %s" % [speaker,", ".join(PackedStringArray((tally[2] as Dictionary).keys()))])
		if int(tally[1])*3>int(tally[0])+2: failures.append("%s uses an address in %d of %d lines" % [speaker,int(tally[1]),int(tally[0])])
	if questions>0 and float(answered)/float(questions)<0.9: failures.append("only %d of %d questions answered from the facts" % [answered,questions])
	if float(words_short)/maxf(1.0,float(words_total))<0.85: failures.append("only %d of %d lines are 20 words or fewer" % [words_short,words_total])
	var mean:=0.0
	for n in per_audience: mean+=float(n)
	mean/=maxf(1.0,float(per_audience.size()))
	if mean>8.0: failures.append("audiences average %.1f lines" % mean)
	# Officials speak in their own manner in at least 70% of the lines that are
	# theirs to colour (facts of the moment use shared, plain phrasing).
	var officials:={}
	for person:Dictionary in HALL._officials(): officials[String(person.name)]=true
	var manner_count:={}
	for row:Dictionary in voice.line_log:
		if not officials.has(String(row.speaker)) or bool(row.get("fact",false)): continue
		var pair:Array=manner_count.get(String(row.speaker),[0,0])
		pair[0]=int(pair[0])+1
		if bool(row.manner): pair[1]=int(pair[1])+1
		manner_count[String(row.speaker)]=pair
	var shares:PackedStringArray=PackedStringArray()
	for speaker in manner_count:
		var pair:Array=manner_count[speaker]
		shares.append("%s %d/%d" % [speaker,int(pair[1]),int(pair[0])])
		if int(pair[0])>=4 and float(pair[1])/float(pair[0])<0.7: failures.append("%s spoke in their manner only %d of %d times" % [speaker,int(pair[1]),int(pair[0])])
	out.append("Officials' lines in their own manner: "+", ".join(shares))
	out.append("Most manners held by one person: %d" % _max_models())
	print("AUDIENCE_TRANSCRIPT manner shares: "+", ".join(shares))
	print("AUDIENCE_TRANSCRIPT models per person: max %d" % _max_models())

func _max_models()->int:
	var most:=0
	for speaker in models_by_person: most=maxi(most,(models_by_person[speaker] as Dictionary).size())
	return most
