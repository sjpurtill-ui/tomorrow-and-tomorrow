extends Node
## Reads a transcript from tests/audience_transcript_dump.gd (reports/audience/
## transcript_3yr.txt) or a fun-harness JSONL (tests/fun_audit/fun_playtest.gd)
## and reports how many spoken lines read as invented maxims
## (scripts/plain_speech.gd), how many court members chimed in per audience,
## and a sample of lines.
##   <godot> --headless --path <worktree> res://tools/plain_speech_survey.tscn -- --file=<abs path> [--sample=10]

const Plain:=preload("res://scripts/plain_speech.gd")

func _arg(n:String,f:String)->String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s="%n): return a.substr(n.length()+3)
	return f

func _ready()->void:
	var path:=_arg("file","")
	var sample_n:=int(_arg("sample","10"))
	if path.is_empty() or not FileAccess.file_exists(path):
		print("PLAIN_SURVEY no file: ",path); get_tree().quit(2); return
	var text:=FileAccess.get_file_as_string(path)
	var lines:Array=[]          # every spoken line (not the ruler, not stage directions)
	var court_counts:Array=[]   # court-member lines per audience
	var objections:Array=[]     # option-card voices
	if path.ends_with(".jsonl"):
		for row_text in text.split("\n",false):
			var row:Variant=JSON.parse_string(row_text)
			if not row is Dictionary or String((row as Dictionary).get("t",""))!="audience": continue
			var speaker:=String((row as Dictionary).get("speaker",""))
			var n:=0
			for entry in (row as Dictionary).get("lines",[]):
				var e:=String(entry)
				var cut:=e.find(": ")
				if cut<0: continue
				var who:=e.substr(0,cut)
				var said:=e.substr(cut+2)
				if who=="You" or who.is_empty() or said.begins_with("["): continue
				lines.append(said)
				if who!=speaker and not speaker.is_empty() and not speaker in who: n+=1
			court_counts.append(n)
			for o in (row as Dictionary).get("options",[]):
				var parts:=String(o).split(" | ")
				if parts.size()>1: objections.append(parts[1])
	else:
		var court:={}
		var re:=RegEx.new(); re.compile("^  (.+?)( \\[[^\\]]*\\])?( \\(aside\\))?: (.*)$")
		var n:=-1
		for raw in text.split("\n"):
			var l:=String(raw)
			if l.begins_with("Court: "):
				for part in l.substr(7).split(", "): court[String(part).get_slice(" (",0).strip_edges()]=true
				continue
			if l.begins_with("Day ") and " · " in l:
				if n>=0: court_counts.append(n)
				n=0
				continue
			var m:=re.search(l)
			if m==null: continue
			var who:=m.get_string(1)
			var said:=m.get_string(4)
			if who=="You" or who=="(narrator)" or who=="Answer" or said.begins_with("["): continue
			lines.append(said)
			if court.has(who) and n>=0: n+=1
		if n>=0: court_counts.append(n)
	var survey:=Plain.survey(lines,40)
	var total_court:=0
	for c in court_counts: total_court+=int(c)
	var audiences:=court_counts.size()
	print("PLAIN_SURVEY file=%s" % path.get_file())
	print("PLAIN_SURVEY lines=%d flagged=%d share=%.3f audiences=%d court_lines=%d court_lines_per_audience=%.2f" % [int(survey.lines),int(survey.flagged),float(survey.share),audiences,total_court,(float(total_court)/audiences) if audiences>0 else 0.0])
	if not objections.is_empty():
		var os:=Plain.survey(objections,5)
		print("PLAIN_SURVEY option_voices=%d flagged=%d" % [int(os.lines),int(os.flagged)])
	for e in survey.examples: print("  FLAG [%s] %s" % [String(e.why),String(e.line)])
	var rng:=RandomNumberGenerator.new(); rng.seed=77013
	var picked:={}
	for i in mini(sample_n,lines.size()):
		var k:=rng.randi_range(0,lines.size()-1)
		var tries:=0
		while picked.has(k) and tries<20: k=rng.randi_range(0,lines.size()-1); tries+=1
		picked[k]=true
		print("  SAMPLE %s" % String(lines[k]))
	get_tree().quit(0)
