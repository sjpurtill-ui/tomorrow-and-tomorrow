extends GdUnitTestSuite
## THE COURT EVALUATION: does the court listen, and do the correct thing?
##
## Runs every case in tests/court_eval/cases.json through the real court
## (the audience modal's _speak(), its voice, the order reader, the engine) on
## the offline path, the stubbed live-reader path (the case's ideal reading)
## and, for grave group orders, a sloppy reading that names the one before
## the ruler as the victim. See tests/court_eval/harness.gd for the checks.
##
## It REPORTS instead of asserting each case: a scoreboard by path and domain,
## every failing case with a one-line reason, and the failures grouped by
## check. ONE summary assertion holds the pass counts at or above BASELINE;
## raise BASELINE as fixes land (never lower it to hide a regression).
##
## Environment (all optional):
##   COURT_EVAL_FILTER   only cases whose id or domain contains this (no threshold then)
##   COURT_EVAL_PATHS    e.g. "live" or "offline,sloppy" (no threshold then)
##   COURT_EVAL_VERBOSE  1: print the exchange of every failing case
##   COURT_EVAL_REPORT   a file path: the full results as JSON (outside user://saves)
## Run (headless, fast; clear OPENAI_API_KEY first):
##   <godot> --headless --path <worktree> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/test_court_eval.gd -c --ignoreHeadlessMode

const Harness:=preload("res://tests/court_eval/harness.gd")
const Capture:=preload("res://scripts/interaction_capture.gd")
const Store:=preload("res://scripts/interaction_store.gd")
const SPARE_ROOT:="user://__court_eval_no_records/"
const CASES_PATH:="res://tests/court_eval/cases.json"

## Passing runs required on the full corpus, by path: first measured on
## main at 91356176 (213 cases; offline 135/213, live 185/213, sloppy 41/42);
## Now 252 cases after court 1A + 1B (offline 252, live 252, sloppy 46/46).
## Raise these as the court improves; the results are deterministic.
const BASELINE:={"offline":254,"live":254,"sloppy":46}

var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	# No real key or endpoint reaches this process; every model is a stub.
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT","LEVIATHAN_AI_MODEL","LEVIATHAN_AI_READER_MODEL"]: OS.unset_environment(key)

func after()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	preload("res://scripts/ai_mode.gd").reset_for_tests(preload("res://scripts/ai_mode.gd").SETTINGS_PATH)

func test_the_court_listens_and_does_the_right_thing()->void:
	var h:=Harness.new(self)
	h.load_cases(CASES_PATH)
	assert_array(Array(h.load_errors)).override_failure_message("cases.json is malformed:\n"+"\n".join(h.load_errors)).is_empty()
	var filter:=OS.get_environment("COURT_EVAL_FILTER").strip_edges()
	var only:=OS.get_environment("COURT_EVAL_PATHS").strip_edges()
	var verbose:=OS.get_environment("COURT_EVAL_VERBOSE").strip_edges() in ["1","true","yes"]
	var partial:=filter!="" or only!=""
	var started:=Time.get_ticks_msec()
	# The worlds restore exactly (the harness would be lying otherwise).
	for name in Harness.Fixtures.NAMES:
		var w:=h.fx.use(name)
		assert_bool(w.has("error")).override_failure_message("%s: %s" % [name,String(w.get("error",""))]).is_false()
		if w.has("error"): return
		var first:=h.fx.digest(w)
		GameState.resource_stockpiles["Food"]=1.0; MilitaryCampaign.field_armies.clear(); Hall_clear()
		h.fx.restore(w.snap)
		assert_str(h.fx.digest(w)).override_failure_message("%s does not restore exactly" % name).is_equal(first)
	var built_ms:=Time.get_ticks_msec()-started
	var results:Array[Dictionary]=[]
	var runs:=0
	var captured_before:=int(Capture.captured)
	# Belt and braces: any record that slipped past the switch lands here, never
	# in the player's own interaction file.
	var real_root:=String(Store.user_root)
	Store.user_root=SPARE_ROOT
	for c:Dictionary in h.cases:
		if filter!="" and not (filter in String(c.id) or filter==String(c.get("domain",""))): continue
		for path:String in h.paths_of(c):
			if only!="" and not path in only.split(",",false): continue
			results.append(h.run(c,path))
			runs+=1
		await await_idle_frame()
	# The player's interaction records were not touched.
	Store.user_root=real_root
	var spilled:=DirAccess.dir_exists_absolute(SPARE_ROOT)
	if spilled:
		for f in DirAccess.get_files_at(SPARE_ROOT): DirAccess.remove_absolute(SPARE_ROOT+f)
		DirAccess.remove_absolute(SPARE_ROOT)
	assert_bool(spilled or int(Capture.captured)!=captured_before).override_failure_message("the evaluation tried to write interaction records").is_false()
	var board:=_scoreboard(results)
	var elapsed:=Time.get_ticks_msec()-started
	print(_render(board,results,verbose,runs,elapsed,built_ms))
	var report_path:=OS.get_environment("COURT_EVAL_REPORT").strip_edges()
	if report_path!="" and not "user://saves" in report_path:
		var f:=FileAccess.open(report_path,FileAccess.WRITE)
		if f!=null:
			f.store_string(JSON.stringify({"board":board,"results":results},"  "))
			f.close()
	if partial: return
	# The one assertion: no path falls below its baseline.
	var short:=PackedStringArray()
	for path in BASELINE:
		var got:=int(((board.paths as Dictionary).get(path,{}) as Dictionary).get("pass",0))
		if got<int(BASELINE[path]): short.append("%s %d < %d" % [path,got,int(BASELINE[path])])
	assert_bool(short.is_empty()).override_failure_message("The court fell below its baseline: "+", ".join(short)).is_true()

func Hall_clear()->void:
	preload("res://scripts/audience_hall.gd").state().get("queue",[]).clear()

# --------------------------------------------------------------------------
# The scoreboard
# --------------------------------------------------------------------------

func _scoreboard(results:Array[Dictionary])->Dictionary:
	var paths:={}; var domains:={}; var codes:={}; var sources:={}
	for r in results:
		var p:=String(r.path); var d:=String(r.domain)
		if not paths.has(p): paths[p]={"pass":0,"total":0}
		paths[p].total+=1
		if bool(r.ok): paths[p].pass+=1
		var key:="%s|%s" % [d,p]
		if not domains.has(key): domains[key]={"pass":0,"total":0}
		domains[key].total+=1
		if bool(r.ok): domains[key].pass+=1
		var src:="%s|%s" % [String(r.get("source","")),p]
		if not sources.has(src): sources[src]={"pass":0,"total":0}
		sources[src].total+=1
		if bool(r.ok): sources[src].pass+=1
		var counted:={}
		for f in r.fails:
			var code:=String((f as Dictionary).code)
			if counted.has(code): continue
			counted[code]=true
			if not codes.has(code): codes[code]={}
			codes[code][p]=int((codes[code] as Dictionary).get(p,0))+1
	return {"paths":paths,"domains":domains,"codes":codes,"sources":sources}

func _render(board:Dictionary,results:Array[Dictionary],verbose:bool,runs:int,elapsed:int,built_ms:int)->String:
	var out:=PackedStringArray()
	out.append("")
	out.append("=========================== COURT EVALUATION ===========================")
	out.append("runs %d   time %.1f s (worlds %.1f s)" % [runs,float(elapsed)/1000.0,float(built_ms)/1000.0])
	for p in ["offline","live","sloppy"]:
		var row:Dictionary=(board.paths as Dictionary).get(p,{"pass":0,"total":0})
		if int(row.total)>0: out.append("  %-8s %4d / %-4d  (%d%%)" % [p,int(row.pass),int(row.total),roundi(100.0*float(row.pass)/float(row.total))])
	out.append("by domain            offline      live        sloppy")
	var names:={}
	for key in (board.domains as Dictionary): names[String(key).get_slice("|",0)]=true
	var sorted:=names.keys(); sorted.sort()
	for d in sorted:
		var cells:=PackedStringArray()
		for p in ["offline","live","sloppy"]:
			var row:Dictionary=(board.domains as Dictionary).get("%s|%s" % [d,p],{})
			cells.append(("%3d/%-3d" % [int(row.pass),int(row.total)]) if not row.is_empty() else "   -   ")
		out.append("  %-18s %s    %s    %s" % [String(d),cells[0],cells[1],cells[2]])
	var user_rows:=PackedStringArray()
	for p in ["offline","live","sloppy"]:
		var row:Dictionary=(board.sources as Dictionary).get("user|%s" % p,{})
		if not row.is_empty(): user_rows.append("%s %d/%d" % [p,int(row.pass),int(row.total)])
	if not user_rows.is_empty(): out.append("the user's own lines: "+"   ".join(user_rows))
	out.append("failures by check (cases failing it, by path):")
	var codes:Array=(board.codes as Dictionary).keys()
	codes.sort_custom(func(a:Variant,b:Variant)->bool: return _total(board.codes[a])>_total(board.codes[b]))
	for code in codes:
		var by:Dictionary=board.codes[code]
		out.append("  %-16s %s" % [String(code),"  ".join(PackedStringArray(by.keys().map(func(k:Variant)->String: return "%s %d" % [String(k),int(by[k])])))])
	out.append("failing cases:")
	for r in results:
		if bool(r.ok): continue
		var first:Dictionary=(r.fails as Array)[0]
		var more:=(r.fails as Array).size()-1
		out.append("  %-44s [%s] s%d %s: %s%s" % [String(r.id),String(r.path),int(first.step),String(first.code),String(first.text).substr(0,190),(" (+%d more)" % more) if more>0 else ""])
		if verbose:
			for f in r.fails: out.append("      - s%d %s: %s" % [int(f.step),String(f.code),String(f.text)])
			for s in r.log:
				out.append("      > You: %s" % String(s.say))
				out.append("        calls: %s" % ", ".join(PackedStringArray(s.calls)))
				for l in s.lines: out.append("        | %s" % String(l).substr(0,260))
	out.append("========================================================================")
	return "\n".join(out)

static func _total(by:Dictionary)->int:
	var n:=0
	for k in by: n+=int(by[k])
	return n
