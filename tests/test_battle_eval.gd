extends GdUnitTestSuite
## THE BATTLE EVALUATION: do our wars play out right, and does the player see
## them right?
##
## Plays every scenario in tests/battle_eval/scenarios.gd end to end through
## the real engine (tests/battle_eval/runners.gd, harness.gd): bands and
## hosts of every age and size in the open, at a ford, in a pass, by night,
## hungry; raids on home; a town stormed and besieged; a garrison attacked;
## many battles at once; marches round water and over hills; the court's war
## order; the war leader's clashes; a chase; a recall; a save mid-battle;
## orders given during and after fights; and rivals fighting where our
## watchers can see. For each battle it checks the outcome against historical
## ranges, the ledgers before and after, the one report and Chronicle entry,
## the record stepped through, and the battle panel and the map's marks day
## by day against the engine (see harness.gd for every check).
##
## It REPORTS instead of asserting each scenario: a scoreboard by kind and by
## check, and every failing scenario with its reasons. ONE summary assertion
## holds the passing count at or above BASELINE; raise BASELINE as fixes land
## (never lower it to hide a regression).
##
## Environment (all optional):
##   BATTLE_EVAL_FILTER   only scenarios whose id or kind contains this (no threshold then)
##   BATTLE_EVAL_VERBOSE  1: every failure of every failing scenario
##   BATTLE_EVAL_REPORT   a file path: the full results as JSON (outside user://saves)
## Run (headless, fast):
##   <godot> --headless --path <worktree> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/test_battle_eval.gd -c --ignoreHeadlessMode

const Runners:=preload("res://tests/battle_eval/runners.gd")
const Scenarios:=preload("res://tests/battle_eval/scenarios.gd")

## Scenarios that must pass. First measured on main at f426bd30: 9 of 62.
## Raise it as fixes land; the results are deterministic.
const BASELINE:={"pass":9}

var _processing:Dictionary={}


func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()


func after()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	CivilizationSystem.set_ground_survey_authority(Callable())
	preload("res://scripts/army_land_route.gd").clear_cache()
	WorldSimulation.enabled=false
	WorldSimulation.clear()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	for node:Node in _processing: node.set_process(bool(_processing[node]))


func test_our_wars_play_out_right_and_are_seen_right()->void:
	var filter:=OS.get_environment("BATTLE_EVAL_FILTER").strip_edges()
	var verbose:=OS.get_environment("BATTLE_EVAL_VERBOSE").strip_edges() in ["1","true","yes"]
	var started:=Time.get_ticks_msec()
	var runner:=Runners.new(self)
	var results:Array[Dictionary]=[]
	var all:=Scenarios.all()
	var ids:={}
	for sc:Dictionary in all:
		assert_bool(ids.has(String(sc.id))).override_failure_message("two scenarios are called %s" % String(sc.id)).is_false()
		ids[String(sc.id)]=true
	for sc:Dictionary in all:
		if filter!="" and not (filter in String(sc.id) or filter==String(sc.get("kind",""))): continue
		results.append(runner.run(sc))
		await await_idle_frame()
	var board:=_scoreboard(results)
	print(_render(board,results,verbose,Time.get_ticks_msec()-started))
	var report_path:=OS.get_environment("BATTLE_EVAL_REPORT").strip_edges()
	if report_path!="" and not "user://saves" in report_path:
		var file:=FileAccess.open(report_path,FileAccess.WRITE)
		if file!=null:
			file.store_string(JSON.stringify({"board":board,"results":results},"  "))
			file.close()
	if filter!="": return
	assert_int(int(board.pass)).override_failure_message("The battle evaluation fell below its baseline: %d < %d passing" % [int(board.pass),int(BASELINE.pass)]).is_greater_equal(int(BASELINE.pass))


# --------------------------------------------------------------------------
# The scoreboard
# --------------------------------------------------------------------------

func _scoreboard(results:Array[Dictionary])->Dictionary:
	var kinds:={}; var codes:={}; var passed:=0
	for r in results:
		var k:=String(r.kind)
		if not kinds.has(k): kinds[k]={"pass":0,"total":0}
		kinds[k].total+=1
		if bool(r.ok): kinds[k].pass+=1; passed+=1
		for code in r.get("codes",[]): codes[String(code)]=int(codes.get(String(code),0))+1
	return {"pass":passed,"total":results.size(),"kinds":kinds,"codes":codes}


func _render(board:Dictionary,results:Array[Dictionary],verbose:bool,elapsed:int)->String:
	var out:=PackedStringArray()
	out.append("")
	out.append("=========================== BATTLE EVALUATION ===========================")
	out.append("scenarios %d   passing %d   time %.1f s" % [int(board.total),int(board.pass),float(elapsed)/1000.0])
	out.append("by kind:")
	var kinds:Array=(board.kinds as Dictionary).keys(); kinds.sort()
	for k in kinds:
		var row:Dictionary=board.kinds[k]
		out.append("  %-14s %3d / %-3d" % [String(k),int(row.pass),int(row.total)])
	out.append("scenarios failing each check:")
	var codes:Array=(board.codes as Dictionary).keys()
	codes.sort_custom(func(a:Variant,b:Variant)->bool: return int(board.codes[a])>int(board.codes[b]))
	for c in codes: out.append("  %-10s %3d" % [String(c),int(board.codes[c])])
	out.append("failing scenarios:")
	for r in results:
		if bool(r.ok): continue
		var fails:Array=r.fails
		var first:Dictionary=fails[0]
		out.append("  %-30s [%s] %s%s" % [String(r.id),String(first.code),String(first.text).substr(0,200),(" (+%d more)" % (fails.size()-1)) if fails.size()>1 else ""])
		if verbose:
			for f in fails.slice(1): out.append("      - %s: %s" % [String((f as Dictionary).code),String((f as Dictionary).text).substr(0,240)])
			for n in r.get("notes",[]): out.append("      . %s" % String(n))
	out.append("slowest: %s" % ", ".join(PackedStringArray(_slowest(results))))
	out.append("==========================================================================")
	return "\n".join(out)


func _slowest(results:Array[Dictionary])->Array:
	var sorted:=results.duplicate()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.ms)>float(b.ms))
	var out:Array=[]
	for r in sorted.slice(0,5): out.append("%s %.0f ms" % [String(r.id),float(r.ms)])
	return out
