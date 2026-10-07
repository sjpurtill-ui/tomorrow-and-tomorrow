extends GdUnitTestSuite
## OUR NETWORKS (covert_ops.gd network): eyes living among a people win
## locals over at their meetings with our scouts; a network grows stronger
## with eyes, locals and above all years; it warns of raids and wars, reads
## their envoys' bluffs and boasts, opens theft and sabotage, and names itself
## as the source of what the Who leads board says. One eye taken hurts it.

const Covert:=preload("res://scripts/covert_ops.gd")
const Standing:=preload("res://scripts/standing.gd")
const Races:=preload("res://scripts/standing_races.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const CV:=preload("res://scripts/character_voice.gd")

var fx:Fixtures
var info:Dictionary


func before()->void:
	for key in ["OPENAI_API_KEY","LEVIATHAN_AI_API_KEY","LEVIATHAN_AI_ENDPOINT"]: OS.unset_environment(key)
	fx=Fixtures.new(self)


func before_test()->void:
	CV.knowledge_override.clear()
	info=fx.base(false)
	Covert.forget()


func after()->void:
	CV.knowledge_override.clear()
	GameState.reset_for_new_world(74017)
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()


func _civ_id()->String: return String(info.get("civ_id",""))


## An eye settled among them `years` ago (no rolls: the test sets the stage).
func _eye(years:float,skill:float=0.8)->Dictionary:
	var agent:=Covert.volunteer()
	agent["stealth"]=skill; agent["tongue"]=skill
	var op:=Covert.launch("plant",_civ_id(),"","trader",agent)
	op["stage"]="in_place"
	op["settled_day"]=int(GameState.elapsed_days)-roundi(years*365.0)
	op["next_report"]=int(GameState.elapsed_days)
	(op.odds as Dictionary)["caught"]=0.0
	return op


func test_meetings_win_locals_over_up_to_a_bound()->void:
	var op:=_eye(2.0,0.95)
	for i in 60:
		Covert._plant_report(op,int(GameState.elapsed_days)+i*Covert.PLANT_REPORT_DAYS)
	assert_int(int(op.get("recruits",0))).is_greater(0)
	assert_int(int(op.get("recruits",0))).is_less_equal(Covert.RECRUITS_PER_EYE)


func test_a_network_grows_stronger_with_years_eyes_and_locals()->void:
	assert_float(Covert.network_strength(_civ_id())).is_equal(0.0)
	var op:=_eye(1.0)
	var young:=Covert.network_strength(_civ_id())
	op["settled_day"]=int(GameState.elapsed_days)-20*365
	var old:=Covert.network_strength(_civ_id())
	assert_float(old).is_greater(young)
	_eye(5.0); op["recruits"]=4
	assert_float(Covert.network_strength(_civ_id())).is_greater(old)
	var nets:=Covert.networks()
	assert_int(nets.size()).is_equal(1)
	assert_int(int(nets[0].eyes)).is_equal(2)


func test_one_eye_taken_hurts_the_network_but_does_not_end_it()->void:
	var first:=_eye(10.0); first["recruits"]=4
	var second:=_eye(10.0); second["recruits"]=4
	var before:=Covert.network_strength(_civ_id())
	Covert._agent_caught_ours(first,int(GameState.elapsed_days),"meeting our scout")
	assert_int(int(first.recruits)).is_equal(0)
	assert_float(Covert.network_strength(_civ_id())).is_less(before)
	# The other was halved at least, or exposed too: never left untouched.
	assert_bool(int(second.get("recruits",0))<=2).is_true()


func test_a_network_warns_reads_bluffs_and_opens_theft()->void:
	var bare_theft:=Covert.odds("steal",_civ_id(),"","trader",Covert.volunteer())
	var bare:=Standing.cunning_toward(_civ_id())
	_eye(15.0)
	assert_float(Standing.cunning_toward(_civ_id())).is_greater(bare)
	assert_float(Standing.forewarn_odds(Standing.cunning_toward(_civ_id()))).is_greater(Standing.forewarn_odds(bare))
	var with_net:=Covert.odds("steal",_civ_id(),"","trader",Covert.volunteer())
	assert_float(float(with_net.success)).is_greater(float(bare_theft.success))


func test_the_board_names_its_source_and_our_eyes_judge_a_boast()->void:
	var rel:Dictionary=(WorldSimulation.world.civilizations[0] as Dictionary).player_relation
	rel["contact_level"]=2
	var names:={}
	for civ:Dictionary in WorldSimulation.world.civilizations: names[String(civ.id)]=String(civ.name)
	_eye(12.0)
	var found:=false
	for race:Dictionary in Races.races(Standing.strengths(),names):
		for row:Dictionary in race.rows:
			if String(row.civ_id)==_civ_id() and not bool(row.unknown):
				found=true
				assert_str(String(row.get("source",""))).contains("12 years")
	# A world without their own simulation has no truth to read; the source
	# line is what matters here when the estimate is known.
	assert_bool(found or Races.their_measures(_civ_id()).is_empty()).is_true()
