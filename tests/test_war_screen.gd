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
	assert_object(row.find_child("Odds",true,false)).is_not_null()
	for id in ["leave","defend","punish","take","peace","pay"]:assert_object(row.find_child("Stance_%s" % id,true,false)).is_not_null()
	assert_object(board.find_child("Leader_war_leader",true,false)).is_not_null()
	# A general can be named from here; the war council gives them work.
	var name_one:Button=board.find_child("NameGeneral",true,false)
	assert_object(name_one).is_not_null()
	name_one.pressed.emit()
	assert_str(board.feedback.text).contains("general")
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
	assert_str(String(answer.get("says",""))).contains("The army is now kept at 5% of the people")
	# The war leader's next look sends nobody home.
	assert_dict(Law.keep(MilitaryCampaign,int(WorldSimulation.state.elapsed_days),true)).is_empty()
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(kept+more)

func test_the_war_leader_drills_the_best_foot_our_people_can_arm()->void:
	var pick:=Law.kit(MilitaryCampaign)
	# Early on that is spears or the plain levy: never a kit nobody can make.
	assert_str(String(pick.unit)).is_not_empty()
	if String(pick.item)!="":assert_bool(MilitaryCampaign._training_gate(String(pick.unit),String(pick.item)).has("error")).is_false()

func test_each_leader_reads_by_what_they_are_best_and_worst_at()->void:
	assert_str(Board.skill_words({"command":0.5,"tactics":0.5,"resolve":0.95,"logistics":0.2})).is_equal("Best at holding firm (5/5) · weakest at supply (1/5)")
	assert_str(Board.skill_words({"command":0.5,"tactics":0.5,"resolve":0.5,"logistics":0.5})).is_equal("Even in every skill (3/5)")
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

func test_a_leader_with_bands_shows_men_will_and_fed_as_bars()->void:
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	var row:Control=board._leader_row({"id":"war_leader","leader":{"name":"Corvan","title":"War leader at home","commander":{"command":0.6}},"bands":[1,2],"men":18,"full":33,"will":0.4,"supply":0.86,"hungry":0,"places":{"Ashford":2}})
	var bars:Node=row.find_child("Bars",true,false)
	assert_object(bars).is_not_null()
	assert_str((bars as Control).tooltip_text).is_equal("Men 18 of 33 · will 40% · fed 86%")
	row.free()

func test_an_open_menu_is_never_rebuilt_under_the_rulers_hand()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	var row:Node=board.find_child("Enemy_%s" % civ_id,true,false)
	var take:MenuButton=row.find_child("Stance_take",true,false)
	# Their dead change while the ruler has a menu of that row open.
	take.get_popup().visible=true
	WAR.front(civ_id).merge({"their_dead":7},true)
	board.refresh()
	assert_bool(is_instance_valid(take) and take.is_inside_tree()).is_true()
	# Once it closes, the row is read again.
	take.get_popup().visible=false
	board.refresh()
	assert_object(board.find_child("Enemy_%s" % civ_id,true,false)).is_not_same(row)

func test_a_besieged_home_is_yielded_only_by_the_rulers_second_press()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	MilitaryCampaign.active_siege={"id":"s1","mode":"defensive","attacker_id":civ_id,"start_day":2,"home_city":{"id":"home","name":"Ashford"},"threat":{"source_civ_id":civ_id}}
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	var give:Button=board.find_child("YieldHome",true,false)
	assert_object(give).is_not_null()
	assert_str(give.text).is_equal("Yield Ashford")
	# The first press only asks again; the siege stands.
	give.pressed.emit()
	assert_str(give.text).is_equal("Press again to yield Ashford")
	assert_str(String(MilitaryCampaign.active_siege.get("id",""))).is_equal("s1")
	# The alerts under the clock tell it while it lasts.
	var fighting:=preload("res://scripts/hud/army_alerts.gd").alerts().filter(func(a:Dictionary)->bool:return String(a.id)=="battle")
	assert_str(String((fighting[0].lines as PackedStringArray)[0])).starts_with("Ashford besieged · day ")
	MilitaryCampaign.active_siege={}

func test_the_army_reads_where_every_soldier_is_and_what_they_carry()->void:
	var Forces:=preload("res://scripts/hud/war_forces_model.gd")
	# Five keep the watch at home and the army is called up beside them.
	WorldSimulation.state.population_allocations["Defense"]=5
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("The watch",[{"id":1,"unit":"levy","weapon":"improvised","count":5,"equipment":5,"training":0.5}],1,1)
	Law.choose(MilitaryCampaign,"some")
	var rows:=Forces.rows(MilitaryCampaign)
	var kinds:=rows.map(func(r:Dictionary)->String:return String(r.kind))
	assert_array(kinds).contains(["home","drill"])
	var home:Dictionary=rows[kinds.find("home")]
	assert_str(String(home.title)).starts_with("At home in ")
	assert_str(String(home.doing)).contains("keep the watch")
	assert_str(String(home.kit)).is_not_empty()
	var drill:Dictionary=rows[kinds.find("drill")]
	assert_int(int(drill.men)).is_equal(Law.under_arms(MilitaryCampaign))
	# The board shows them in plain words: shares as numbers, a row per place.
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	assert_str((board.find_child("Level_some",true,false) as Button).text).is_equal("3%")
	assert_object(board.find_child("Force_home",true,false)).is_not_null()
	assert_object(board.find_child("Force_drill",true,false)).is_not_null()
	assert_object(board.find_child("DrawnFrom",true,false)).is_not_null()
	WorldSimulation.state.population_allocations.erase("Defense")
