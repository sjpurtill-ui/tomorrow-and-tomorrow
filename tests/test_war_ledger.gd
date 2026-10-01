extends GdUnitTestSuite
## THE WAR LEDGER (hud/war_ledger_model.gd, hud/war_ledger_board.gd): the
## Feuds page reads each feud as HOI4's war overview reads a war, from the one
## ledger. It shows the dead on each side, how worn each people is (with the
## engine's turning points), the quiet since blood (hot, simmering, cold),
## what would end it, and our bands at their towns. A settled feud stays a
## while, saying how it ended.

const WAR:=preload("res://scripts/war_loop.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const Model:=preload("res://scripts/hud/war_ledger_model.gd")
const Board:=preload("res://scripts/hud/war_ledger_board.gd")

var probe:Node
var civ_id:=""
var _opponents:=0

func before_test()->void:
	_opponents=GameState.opponent_count
	probe=auto_free(HallProbe.new())
	probe._base()
	GameState.opponent_count=4
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	probe._people(140)
	probe._refill()
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2; relation.met_day=0
		for other in civ.relations: civ.relations[other].at_war=false
	GameState.elapsed_days=10
	civ_id=String(CivilizationSystem.civilizations[0].id)
	MilitaryCampaign.reset_for_new_world()

func after_test()->void:
	GameState.elapsed_days=0
	if _opponents>0: GameState.opponent_count=_opponents
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()

func _feud()->Dictionary:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	var f:=WAR.front(civ_id)
	f["pending"]={}
	f.merge({"our_dead":3,"their_dead":7,"our_exh":0.1,"their_exh":0.45,"raids":2,"strikes":1,"last_harm":10},true)
	return f

func test_a_feud_reads_as_a_war_overview_reads_a_war()->void:
	_feud()
	var entries:=Model.entries(50)
	assert_int(entries.size()).is_equal(1)
	var e:Dictionary=entries[0]
	assert_str(String(e.kind)).is_equal("feud")
	assert_bool(bool(e.hot)).is_true()
	assert_int(int(e.our_dead)).is_equal(3)
	assert_int(int(e.their_dead)).is_equal(7)
	assert_float(float(e.their_worn)).is_equal_approx(0.45,0.0001)
	assert_int(int(e.quiet)).is_equal(40)
	assert_int(int(e.raids)).is_equal(2)
	assert_str(String(e.cause)).contains("Qira")
	assert_str(Model.state_word(e)).is_equal("Hot")
	# The clock and the ways out, in the engine's own numbers.
	assert_str(Model.clock_words(e)).contains("40 days since blood")
	var ends:=Model.ending_words(e)
	assert_str(ends).contains("blood price of %d food" % roundi(WAR.blood_price(civ_id)))
	assert_str(ends).contains("after %d quiet days" % WAR.PEACE_QUIET_DAYS)
	# A year of quiet: no longer hot, still a feud.
	var later:=Model.entries(10+WAR.FEUD_HOT_DAYS+5)
	assert_str(Model.state_word(later[0])).is_equal("Simmering")
	assert_str(Model.clock_words(later[0])).contains("Cold in")

func test_a_settled_feud_stays_a_while_saying_how_it_ended()->void:
	_feud()
	WAR._end_feud(civ_id,20,"blood price","The blood price is paid.")
	var entries:=Model.entries(30)
	assert_int(entries.size()).is_equal(1)
	assert_str(String(entries[0].kind)).is_equal("ended")
	assert_str(String(entries[0].how_words)).is_equal("a blood price was paid")
	assert_int(int(entries[0].their_dead)).is_equal(7)
	assert_array(Model.entries(20+Model.ENDED_SHOWN_DAYS+1)).is_empty()

func test_our_band_at_their_town_is_listed_with_its_kit()->void:
	_feud()
	MilitaryCampaign.field_armies.assign([{"army_id":4,"name":"Ennis's band","troops":4,"status":"stationed","location_name":"Eldwick","city_operation":{"civ_id":civ_id},
		"formations":[{"unit":"spearman","weapon":"spear","count":4}]}])
	var bands:Array=Model.bands_by_civ().get(civ_id,[])
	assert_int(bands.size()).is_equal(1)
	assert_str(String(bands[0].where)).is_equal("at Eldwick")
	assert_str(String(bands[0].glyph)).is_equal("spear")
	assert_int((Model.entries(50)[0].bands as Array).size()).is_equal(1)

func test_the_board_draws_peace_or_a_card_with_its_meters()->void:
	var quiet:VBoxContainer=auto_free(Board.new())
	add_child(quiet)
	quiet.setup({})
	assert_object(quiet.find_child("AtPeace",true,false)).is_not_null()
	_feud()
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	var card:Node=board.find_child("Feud_%s" % civ_id,true,false)
	assert_object(card).is_not_null()
	assert_int(board.cards.size()).is_equal(1)
	var shown:Dictionary=board.cards[0]
	assert_int((shown.dead as Board.DeadBars).theirs).is_equal(7)
	assert_float((shown.worn as Board.WornBars).theirs).is_equal_approx(0.45,0.0001)
	assert_object(shown.quiet).is_not_null()
	var words:PackedStringArray=(shown.chips as HFlowContainer).get_meta("words",PackedStringArray())
	assert_bool(words.has("Their raids 2")).is_true()
	assert_bool(words.has("Our strikes 1")).is_true()
	assert_str((shown.ends as Label).text).contains("blood price")
