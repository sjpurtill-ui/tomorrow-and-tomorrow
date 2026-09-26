extends GdUnitTestSuite
## The Council of Nations sheet (scripts/commitment_screen.gd): the layout's
## essentials are present, dates read in game-calendar words, and every
## function of the old screen is still reachable.

const Screen:=preload("res://scripts/commitment_screen.gd")
const Fixture:=preload("res://tests/commitment_ui_probe.gd")

var first:=""

func before_test()->void:
	first=Fixture.build_fixture()

func id(index:int)->String: return String(CivilizationSystem.civilizations[index].id)

func open(draft:Dictionary={})->Control:
	var screen:Control=auto_free(Screen.new())
	screen.set("civ_id",first);screen.set("draft",draft)
	add_child(screen)
	return screen

func test_layout_shows_ties_league_calls_and_dated_ledger()->void:
	var screen:=open()
	await await_idle_frame()
	assert_str((screen.find_child("Title",true,false) as Label).text).is_equal("The Council of Nations")
	assert_int(screen.peoples_box.get_child_count()).is_equal(3)
	# The addressed people leads, with its protection and marriage shown as ties.
	assert_str(String(screen.peoples_box.get_child(0).name)).is_equal("People_"+first)
	var ties:Node=screen.peoples_box.get_child(0).find_child("Ties",true,false)
	assert_object(ties).is_not_null()
	assert_int(ties.get_child_count()).is_greater_equal(3)
	assert_object(screen.find_child("LeagueTerms",true,false)).is_not_null()
	for member:String in ["player",first,id(1)]: assert_object(screen.find_child("Member_"+member,true,false)).is_not_null()
	# A real call on your promise is actionable; relief on the road is listed.
	assert_object(screen.find_child("SendFood_"+id(1),true,false)).is_not_null()
	assert_object(screen.find_child("Relief_relief_9",true,false)).is_not_null()
	for label in screen.ledger_box.find_children("When","Label",true,false):
		assert_str((label as Label).text).starts_with("YEAR ")
	var ledger:=""
	for label in screen.ledger_box.find_children("*","Label",true,false): ledger+=(label as Label).text+"\n"
	assert_str(ledger).not_contains(id(1))
	assert_str(ledger).not_contains("Day ")
	# No all-caps buttons.
	for button in screen.find_children("*","Button",true,false):
		var text:=(button as Button).text
		if text.length()>3: assert_bool(text==text.to_upper()).is_false()

func test_every_offer_and_aid_remains_reachable()->void:
	var screen:=open()
	await await_idle_frame()
	# A league member offers the league's business.
	for action:String in ["protection","set_goal","debate_war","leave_faction"]:
		assert_object(screen.offers_row.find_child("Offer_"+action,false,false)).is_not_null()
	screen.choose("set_goal");screen.pick_goal("exchange")
	assert_str(String(screen.selected_terms().goal)).is_equal("exchange")
	assert_object(screen.find_child("Aims",true,false)).is_not_null()
	screen.choose("debate_war")
	assert_object(screen.find_child("Choice_"+id(2),true,false)).is_not_null()
	screen.pick_target(id(2))
	assert_str(String(screen.selected_terms().target_id)).is_equal(id(2))
	# Someone outside the league can be invited in.
	screen.address(id(2))
	assert_object(screen.offers_row.find_child("Offer_join_faction",false,false)).is_not_null()
	screen.address(first)
	screen.choose("leave_faction")
	assert_bool(screen.send_button.disabled).is_false()
	var sent:Dictionary=screen.send_terms()
	assert_bool(sent.has("error")).is_false()
	assert_str(String(CivilizationSystem.diplomatic_mission.commitment_terms.action)).is_equal("leave_faction")
	# With the envoys away, nothing else can leave, and the sheet says why.
	assert_bool(screen.send_button.disabled).is_true()
	assert_bool(screen.aid_button.disabled).is_true()
	assert_bool(screen.send_food(id(1)).has("error")).is_true()
	assert_bool(screen.outcome.visible).is_true()

func test_food_aid_and_draft_prefill()->void:
	var screen:=open({"action":"found_faction","goal":"routes","target_id":"","siege_id":""})
	await await_idle_frame()
	# The drafted offer is kept even though a league already exists; its blocker shows.
	assert_str(screen.sel_action).is_equal("found_faction")
	assert_object(screen.find_child("Blocker",true,false)).is_not_null()
	assert_bool(screen.send_button.disabled).is_true()
	assert_bool(screen.aid_button.disabled).is_false()
	var sent:Dictionary=screen.send_food(first)
	assert_bool(sent.has("error")).is_false()
	assert_bool(CivilizationSystem.diplomatic_mission.is_empty()).is_false()
