extends GdUnitTestSuite
## THE EYES PAGE (hud/content/dock_content_eyes.gd, hud/covert_board.gd): its
## own rail entry on F3 in the age's word, buttons that set how many of each
## corps are taught (the Pathfinder's same order), and an errand button for
## each people we know that launches a real operation on the odds it shows.

const Covert:=preload("res://scripts/covert_ops.gd")
const Corps:=preload("res://scripts/eyes_corps.gd")
const Board:=preload("res://scripts/hud/covert_board.gd")
const Hud:=preload("res://scripts/hud/command_rail_hud.gd")
const Page:=preload("res://scripts/hud/content/dock_content_eyes.gd")
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
	ForeignDiplomacy.audiences.erase(Corps.KEY)


func after()->void:
	CV.knowledge_override.clear()
	GameState.reset_for_new_world(74017)
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()


func _civ_id()->String: return String(info.get("civ_id",""))


func test_the_eyes_have_their_own_rail_entry_on_f3()->void:
	var found:={}
	for spec:Dictionary in Hud.SECTIONS:
		if String(spec.id)=="eyes": found=spec
	assert_bool(found.is_empty()).is_false()
	assert_str(String(found.tooltip)).contains("F3")
	assert_str(String(Hud.HOTKEYS.get(KEY_F3,""))).is_equal("eyes")
	var page:=Page.new(null,null)
	assert_str(String(page.meta().title)).is_equal(Corps.word("Eyes"))
	assert_str(String((page.tab(0).blocks as Array)[0].type)).is_equal("eyes")


func test_level_buttons_set_each_corps_as_the_pathfinder_would()->void:
	var board:=auto_free(Board.new()) as Board
	add_child(board); board.setup()
	var rows:=Board.level_rows("wary")
	assert_int(rows.size()).is_equal(4)
	assert_bool(bool((rows[0] as Dictionary).active)).is_true()
	var said:=board.set_level("wary","many")
	assert_str(Corps.policy("wary")).is_equal("many")
	assert_str(said).contains("distrust")
	board.set_level("eyes","few")
	assert_str(Corps.policy("eyes")).is_equal("few")
	assert_object(board.find_child("Level_eyes_few",true,false)).is_not_null()
	# The lit level says what it costs in the engine's numbers.
	for row:Dictionary in Board.level_rows("eyes"):
		if bool(row.active): assert_str(String(row.words)).contains("day course")


func test_an_errand_button_shows_odds_and_launches_a_real_operation()->void:
	var civ:=_civ_id()
	assert_str(civ).is_not_empty()
	var rows:=Board.errand_rows()
	var mine:={}
	for r:Dictionary in rows:
		if String(r.civ_id)==civ: mine=r
	assert_bool(mine.is_empty()).override_failure_message("known people missing from the page").is_false()
	var watch:Dictionary=(mine.errands as Array)[0]
	assert_str(String(watch.kind)).is_equal("watch")
	assert_float(float(watch.success)).is_between(0.05,0.99)
	var board:=auto_free(Board.new()) as Board
	add_child(board); board.setup()
	assert_object(board.find_child("Send_watch_%s" % civ,true,false)).is_not_null()
	var before:=Covert.agents_abroad().size()
	var said:=board.send("watch",civ)
	assert_str(said).is_not_empty()
	assert_int(Covert.agents_abroad().size()).is_equal(before+1)
