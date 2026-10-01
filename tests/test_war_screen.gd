extends GdUnitTestSuite
## THE WAR SCREEN (hud/war_board.gd) and HOW MANY SERVE (army_levy_law.gd):
## grand strategy on one page. The ruler chooses a share of the people to
## keep under arms, a stance toward each enemy, and sees the leaders; the war
## leader does the rest. No band is ordered by hand.

const WAR:=preload("res://scripts/war_loop.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const Board:=preload("res://scripts/hud/war_board.gd")

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
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()

func after_test()->void:
	GameState.elapsed_days=0
	if _opponents>0: GameState.opponent_count=_opponents
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()

func test_the_army_is_kept_at_the_share_the_ruler_chooses()->void:
	assert_str(Law.reading(MilitaryCampaign).level).is_equal("")
	# Nobody is called up on its account until the ruler chooses.
	assert_dict(Law.keep(MilitaryCampaign,10,true)).is_empty()
	var people:=int(WorldSimulation.state.population_total)
	var result:=Law.choose(MilitaryCampaign,"some")
	assert_bool(bool(result.ok)).is_true()
	var target:=Law.target_men("some",people)
	assert_int(target).is_equal(roundi(people*0.03))
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(target)
	assert_str(String(result.said)).contains("called up")
	# Fewer: the surplus at home goes back to work.
	Law.choose(MilitaryCampaign,"few")
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(Law.target_men("few",people))
	# The level is saved with the army.
	assert_str(String(MilitaryCampaign.export_state().army_levy_level)).is_equal("few")
	# The same words at any size: a share, never a count.
	assert_str(Law.cost_words("some",1_000_000_000,600_000_000)).starts_with("30,000,000 of 1,000,000,000 serve")

func test_the_war_screen_shows_the_army_our_enemies_and_our_leaders()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	WAR.front(civ_id).merge({"their_dead":3,"our_dead":1,"pending":{}},true)
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	for id in ["few","some","many","war","all"]:assert_object(board.find_child("Level_%s" % id,true,false)).is_not_null()
	assert_object(board.find_child("Strength",true,false)).is_not_null()
	var row:Node=board.find_child("Enemy_%s" % civ_id,true,false)
	assert_object(row).is_not_null()
	for id in ["leave","defend","punish","take","peace","pay"]:assert_object(row.find_child("Stance_%s" % id,true,false)).is_not_null()
	assert_object(board.find_child("Leader_war_leader",true,false)).is_not_null()
	# Who leads against them: the war leader until a general comes forward.
	assert_object(row.find_child("LedBy",true,false)).is_not_null()
	# A stance is the war leader's order, and the row remembers it.
	(row.find_child("Stance_defend",true,false) as Button).pressed.emit()
	assert_str(String(WAR.front(civ_id).get("stance",""))).is_equal("defend")
	assert_int(int(WAR.front(civ_id).get("guard_until",-1))).is_greater(10)
	assert_str(board.feedback.text).is_not_empty()
	# Nothing on the page orders a band by hand.
	for name in ["MoveTo","PutUnder","WholeCommand","Verbs"]:assert_object(board.find_child(name,true,false)).is_null()

func test_the_army_bar_reads_ready_drill_and_waiting_against_the_share()->void:
	assert_str(Board.strength_words({"ready":327,"drill":85,"drill_days":40,"waiting":3,"away":9},424,612)).is_equal("327 ready · 85 in drill, about 40 days · 3 waiting to drill · 9 hurt or away · 188 to call up")
	assert_str(Board.strength_words({"ready":30,"drill":0,"drill_days":0,"waiting":0},30,20)).is_equal("30 ready · 10 above the share")
	assert_str(Board.strength_words({"ready":4,"drill":0,"drill_days":0,"waiting":0},4,-1)).is_equal("4 ready")
	# Nobody out: no fed share to show.
	assert_float(float(Board.strength(MilitaryCampaign).fed)).is_equal(-1.0)

func test_a_levy_ordered_in_court_lifts_the_share_instead_of_being_sent_home()->void:
	var people:=int(WorldSimulation.state.population_total)
	Law.choose(MilitaryCampaign,"few")
	var kept:=Law.under_arms(MilitaryCampaign)
	assert_int(kept).is_equal(Law.target_men("few",people))
	# The ruler calls up more in court than the share keeps.
	var more:=Law.target_men("many",people)-kept
	var answer:Dictionary=preload("res://scripts/home_orders.gd").perform({"kind":"levy","count":more,"recruit":true,"fill":false,"arm_said":true,"unit":"levy","item":""})
	assert_int(int(answer.get("raised",0))).is_equal(more)
	assert_str(Law.reading(MilitaryCampaign).level).is_equal("many")
	assert_str(String(answer.get("says",""))).contains("now keeps the army at")
	# The war leader's next look sends nobody home.
	assert_dict(Law.keep(MilitaryCampaign,int(WorldSimulation.state.elapsed_days),true)).is_empty()
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(kept+more)

func test_the_war_leader_drills_the_best_foot_our_people_can_arm()->void:
	var pick:=Law.kit(MilitaryCampaign)
	# Early on that is spears or the plain levy: never a kit nobody can make.
	assert_str(String(pick.unit)).is_not_empty()
	if String(pick.item)!="":assert_bool(MilitaryCampaign._training_gate(String(pick.unit),String(pick.item)).has("error")).is_false()

func test_each_leader_reads_by_what_they_are_best_and_worst_at()->void:
	assert_str(Board.skill_words({"command":0.5,"tactics":0.5,"resolve":0.95,"logistics":0.2})).is_equal("Best at standing firm (5 of 5) · weakest at keeping them fed (1 of 5)")
	assert_str(Board.skill_words({"command":0.5,"tactics":0.5,"resolve":0.5,"logistics":0.5})).is_equal("Even in every skill: 3 of 5")
	assert_str(Board.skill_words({})).is_empty()
	# The battle report's words for a beaten commander and their captives.
	assert_str(CombatSimulator.captive_words(1)).is_equal("1 prisoner")
	assert_str(CombatSimulator.fate_words("escaped")).is_equal("got away")
	assert_str(CombatSimulator.fate_words("wounded, but escaped")).is_equal("was wounded but got away")

func test_the_watch_at_home_is_not_the_army()->void:
	# Five keep the watch: set to defence work and standing at home.
	WorldSimulation.state.population_allocations["Defense"]=5
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("The watch",[{"id":1,"unit":"levy","weapon":"improvised","count":5,"equipment":5,"training":0.5}],1,1)
	assert_int(int(Law.watch(MilitaryCampaign).kept)).is_equal(5)
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(0)
	var people:=int(WorldSimulation.state.population_total)
	Law.choose(MilitaryCampaign,"some")
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(Law.target_men("some",people))
	# Fewer: the army shrinks, the watch stays whole.
	Law.choose(MilitaryCampaign,"few")
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(Law.target_men("few",people))
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_greater_equal(5)
	assert_int(int(Law.watch(MilitaryCampaign).kept)).is_equal(5)
	assert_int(int(Board.strength(MilitaryCampaign).watch)).is_equal(5)
	WorldSimulation.state.population_allocations.erase("Defense")
