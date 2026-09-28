extends GdUnitTestSuite
## THE LIVE COURT EVALUATION (tests/court_eval/live_eval.gd): the court's cases
## (tests/court_eval/cases.json) read by the REAL model, and its voice's real
## answers to the questions among them. It spends money, so it does nothing
## and passes unless COURT_LIVE_EVAL=1.
##
## Environment:
##   COURT_LIVE_EVAL=1           run it; anything else skips it (nothing spent)
##   COURT_LIVE_EVAL_FILTER      only cases whose id contains this, or whose domain is it
##                               (several, comma-separated: any of them)
##   COURT_LIVE_EVAL_MAX_CALLS   at most this many model calls in this run
##   COURT_LIVE_EVAL_PARTS       "reader", "voice" or both (default "reader,voice")
##   COURT_LIVE_EVAL_DRY=1       no model at all: the reader returns the ideal
##                               reading and the voice a plain line (the
##                               plumbing, free; the reader must score exact)
##   COURT_LIVE_EVAL_REPLAY=<report.json>  no model at all: an earlier run's
##                               readings and replies judged again against
##                               the current engine and checks (free)
##   COURT_LIVE_EVAL_DIR         where the ledger and the reports go (default in live_eval.gd)
##   COURT_LIVE_EVAL_LEDGER      the spend ledger (default <dir>/live_eval_spend.json)
##   COURT_LIVE_EVAL_CAP_USD     a cap lower than $5.00 (never higher)
## The connection is the player's own (PronouncementInterpreter._api_config():
## OPENAI_API_KEY or LEVIATHAN_AI_API_KEY in this process; gpt-6-luna unless
## LEVIATHAN_AI_MODEL says otherwise). Without one the run is skipped with a
## message. The key is never printed, logged or written.
## Run (PowerShell; the first line copies the user-scoped key into this shell,
## as tools/launch_game.ps1 does, without showing it):
##   $env:OPENAI_API_KEY=[Environment]::GetEnvironmentVariable('OPENAI_API_KEY','User'); $env:COURT_LIVE_EVAL='1'
##   <godot> --headless --path <worktree> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/test_court_live_eval.gd -c --ignoreHeadlessMode

const LiveEval:=preload("res://tests/court_eval/live_eval.gd")
const Capture:=preload("res://scripts/interaction_capture.gd")
const Store:=preload("res://scripts/interaction_store.gd")
const SPARE_ROOT:="user://__court_live_eval_no_records/"

var _ran:=false
var _processing:Dictionary={}
var _api_was:=false

func test_the_real_model_reads_the_court(_timeout:=5400000)->void:
	if OS.get_environment("COURT_LIVE_EVAL").strip_edges()!="1":
		print("COURT LIVE EVALUATION skipped: set COURT_LIVE_EVAL=1 to run it (it calls the paid model).")
		assert_bool(true).is_true()
		return
	_ran=true
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	_api_was=bool(GameState.civic_api_enabled)
	var captured_before:=int(Capture.captured)
	# Belt and braces: any record that slipped past the switch lands here, never
	# in the player's own interaction file.
	var real_root:=String(Store.user_root)
	Store.user_root=SPARE_ROOT
	var live:=LiveEval.new(self)
	var report:Dictionary=await live.run_all()
	Store.user_root=real_root
	var spilled:=DirAccess.dir_exists_absolute(SPARE_ROOT)
	if spilled:
		for f in DirAccess.get_files_at(SPARE_ROOT): DirAccess.remove_absolute(SPARE_ROOT+f)
		DirAccess.remove_absolute(SPARE_ROOT)
	if report.has("skipped"):
		print("COURT LIVE EVALUATION skipped: "+String(report.skipped))
		return
	assert_bool(report.has("error")).override_failure_message("The live evaluation could not run: "+String(report.get("error",""))).is_false()
	assert_bool(bool(report.get("key_leak",false))).override_failure_message("The API key reached the evaluation's output; the report was withheld.").is_false()
	assert_bool(spilled or int(Capture.captured)!=captured_before).override_failure_message("The evaluation tried to write interaction records.").is_false()

func after()->void:
	if not _ran: return
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
	GameState.civic_api_enabled=_api_was
	OS.unset_environment("LEVIATHAN_AI_READER_MODEL")
	preload("res://scripts/ai_mode.gd").reset_for_tests(preload("res://scripts/ai_mode.gd").SETTINGS_PATH)
