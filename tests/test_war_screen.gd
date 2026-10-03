extends GdUnitTestSuite
## THE WAR SCREEN (hud/war_board.gd) and HOW MANY SERVE (army_levy_law.gd):
## grand strategy on one page. KEEPING WATCH IS THE MILITARY
## (watch_military.gd): the ruler chooses the share of the people that keeps
## watch (the army), how much of it guards home, a stance toward each enemy,
## and sees the leaders; the war leader does the rest. No band is ordered by
## hand.

const WAR:=preload("res://scripts/war_loop.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const Law:=preload("res://scripts/army_levy_law.gd")
const Board:=preload("res://scripts/hud/war_board.gd")
const Bar:=preload("res://scripts/hud/army_bar.gd")
const MapMode:=preload("res://scripts/hud/war_map_mode.gd")

## A map for the War map to draw on: an orthographic camera looking straight
## down at its target, the towns' cards on their own layer, flat ground.
class FakeMap extends Node3D:
	var camera:Camera3D
	var camera_target:=Vector3.ZERO
	var city_labels:Control
	var capture_render_active:=true
	func _ready()->void:
		camera=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=12.0; add_child(camera); camera.current=true
		var layer:=CanvasLayer.new(); layer.name="CityLabels"; add_child(layer)
		city_labels=Control.new(); layer.add_child(city_labels)
		_update_camera()
	func _height_at(_x:float,_z:float)->float: return 0.0
	func _update_camera()->void:
		camera.global_position=camera_target+Vector3(0,400,0)
		camera.look_at(camera_target,Vector3.FORWARD)
	func _update_scale_lod()->void: pass

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
	if is_instance_valid(MilitaryCampaign.roster_screen):MilitaryCampaign.roster_screen.free()
	GameState.elapsed_days=0
	if _opponents>0: GameState.opponent_count=_opponents
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldSimulation.clear()

func test_the_army_is_kept_at_the_share_the_ruler_chooses()->void:
	# The army's size is the watch share: read from the people's own work.
	assert_str(Law.reading(MilitaryCampaign).level).starts_with("share:")
	var people:=int(WorldSimulation.state.population_total)
	var result:=Law.choose(MilitaryCampaign,"some")
	assert_bool(bool(result.ok)).is_true()
	var target:=Law.target_men("some",people)
	assert_int(target).is_equal(roundi(people*0.03))
	assert_int(MilitaryCampaign.watch_manpower()).is_equal(target)
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(target)
	assert_str(String(result.said)).contains("keep watch")
	# Fewer: the surplus at home goes back to work.
	Law.choose(MilitaryCampaign,"few")
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(Law.target_men("few",people))
	# The share is saved with the army, and the leaders keep it.
	assert_float(float(MilitaryCampaign.export_state().watch_work_share)).is_greater(0.0)
	# The same words at any size: a share, never a count.
	assert_str(Law.cost_words("some",1_000_000_000,600_000_000)).starts_with("30,000,000 of 1,000,000,000 keep watch")

func test_the_war_screen_shows_the_army_our_enemies_and_our_leaders()->void:
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	WAR.front(civ_id).merge({"their_dead":3,"our_dead":1,"pending":{}},true)
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	for id in ["few","some","many","war","all"]:assert_object(board.find_child("Level_%s" % id,true,false)).is_not_null()
	assert_object(board.find_child("Strength",true,false)).is_not_null()
	# Top to bottom: the manpower, the home guard, the offensive troops.
	var order:=["ManpowerCard","GuardCard","OffenseCard","Enemies","Leaders"].map(func(n:String)->int:return (board.find_child(n,true,false) as Control).get_index() if board.find_child(n,true,false).get_parent()==board else (board.find_child(n,true,false).get_parent() as Control).get_index())
	for i in order.size()-1:assert_int(int(order[i])).is_less(int(order[i+1]))
	for name in ["WatchMore","WatchLess","GuardMore","GuardLess","People"]:assert_object(board.find_child(name,true,false)).is_not_null()
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
	assert_str(Board.strength_words({"ready":327,"drill":85,"drill_days":40,"waiting":3,"away":9},424,612)).is_equal("327 ready · 85 in a drill course, about 40 days · 3 joining the watch · 9 hurt or away · 188 to join")
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
	# Those called up keep watch: the share rises to hold them.
	assert_str(Law.reading(MilitaryCampaign).name).is_equal("5%")
	assert_str(String(answer.get("says",""))).contains("called up to keep watch")
	# The war leader's next look sends nobody home.
	assert_int(int(Law.keep(MilitaryCampaign,int(WorldSimulation.state.elapsed_days),true).released)).is_equal(0)
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

func test_the_watch_at_home_is_the_army()->void:
	# Five keep the watch: set to defence work and standing at home. They are
	# the army, all of it.
	WorldSimulation.state.population_allocations["Defense"]=5
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("The watch",[{"id":1,"unit":"levy","weapon":"improvised","count":5,"equipment":5,"training":0.5}],1,1)
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(5)
	var people:=int(WorldSimulation.state.population_total)
	Law.choose(MilitaryCampaign,"some")
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(Law.target_men("some",people))
	assert_int(int(MilitaryCampaign.home_army.get("troops",0))).is_equal(Law.target_men("some",people))
	# Fewer: the watch shrinks, the least drilled first.
	Law.choose(MilitaryCampaign,"few")
	assert_int(Law.under_arms(MilitaryCampaign)).is_equal(Law.target_men("few",people))
	# The home guard is the split's share of it, standing at home.
	assert_int(int(Law.watch(MilitaryCampaign).kept)).is_equal(mini(int(MilitaryCampaign.home_army.troops),roundi(float(MilitaryCampaign._mobilized_count())*MilitaryCampaign.watch_split())))
	assert_int(int(Board.strength(MilitaryCampaign).watch)).is_equal(int(Law.watch(MilitaryCampaign).kept))

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
	# Nobody waits in a drill course: they joined the watch at home at once.
	assert_array(kinds).contains(["home"])
	assert_array(kinds).not_contains(["drill"])
	var home:Dictionary=rows[kinds.find("home")]
	assert_str(String(home.title)).starts_with("At home in ")
	assert_str(String(home.doing)).contains("guard home")
	assert_str(String(home.kit)).is_not_empty()
	assert_int(int(home.men)).is_equal(Law.under_arms(MilitaryCampaign))
	# The board shows them as numbers: shares on the strip, and where they
	# are on the army bar's cards (the levy at home first, with the watch
	# and those in drill).
	var board:VBoxContainer=auto_free(Board.new())
	add_child(board)
	board.setup({})
	assert_str((board.find_child("Level_some",true,false) as Button).text).is_equal("3%")
	assert_object(board.find_child("DrawnFrom",true,false)).is_not_null()
	var levy:Dictionary=Bar.levy_card(MilitaryCampaign)
	assert_int(int(levy.watch)).is_equal(int(Law.watch(MilitaryCampaign).kept))
	assert_int(int(levy.drill)+int(levy.waiting)+int(levy.ready)+int(levy.watch)).is_equal(Law.under_arms(MilitaryCampaign))
	assert_str(String(Bar.war_cards(MilitaryCampaign)[0].kind)).is_equal("levy")
	WorldSimulation.state.population_allocations.erase("Defense")

func test_the_war_screen_keeps_the_map_as_the_screen()->void:
	# HOI4's way: a strip of numbers under the clock, a narrow column at the
	# right edge, and the army bar along the bottom even with no band out.
	WAR.blood_feud(civ_id,10,"the killing of their envoy Qira")
	Law.choose(MilitaryCampaign,"some")
	MilitaryCampaign.open_roster("army")
	var screen=MilitaryCampaign.roster_screen
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(screen.war_mode()).is_true()
	var view:Vector2=screen.get_viewport().get_visible_rect().size
	assert_float(screen.panel.size.x).is_equal(Board.COLUMN_WIDTH)
	assert_float(screen.panel.position.x+screen.panel.size.x).is_equal_approx(view.x-preload("res://scripts/hud/hud_tokens.gd").EDGE_MARGIN,0.5)
	var strip:Control=screen.body.find_child("WarStrip",true,false)
	assert_object(strip).is_not_null()
	assert_bool(strip.top_level).is_true()
	assert_float(strip.position.x+strip.size.x).is_less_equal(screen.panel.position.x)
	# The army bar stands while the War screen is open, the levy leading it.
	assert_bool(Bar.war_open()).is_true()
	var bar:Control=auto_free(Bar.new());add_child(bar)
	bar.place(Rect2(100,600,1000,bar.bar_height()));bar.refresh()
	assert_bool(bar.visible).is_true()
	assert_str(String(bar.cards[0].kind)).is_equal("levy")
	# A click on the map does not close it; Escape does.
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=Vector2(view.x*0.4,view.y*0.5)
	screen._input(click)
	assert_bool(screen.is_queued_for_deletion()).is_false()
	# Sentences live in the tooltips: no line on the screen runs past eight
	# words (the war leader's own reply to a click aside).
	for node in screen.body.find_children("*","",true,false):
		if node is Label and node.name!="Said" and (node as Label).is_visible_in_tree():
			assert_int((node as Label).text.split(" ",false).size()).override_failure_message((node as Label).text).is_less_equal(8)
		if node is Button and (node as Button).is_visible_in_tree():
			assert_int((node as Button).text.split(" ",false).size()).override_failure_message((node as Button).text).is_less_equal(8)
	screen.free()

func test_the_strip_reads_the_same_for_a_village_and_an_empire()->void:
	assert_str(Board.compact(120)).is_equal("120")
	assert_str(Board.compact(48_300)).is_equal("48,300")
	assert_str(Board.compact(1_260_000)).is_equal("1.3 million")
	assert_str(Board.compact(3_400_000_000)).is_equal("3.4 billion")
	assert_str(Board.compact(2_000_000_000)).is_equal("2 billion")


## The user, 2026-10-01: "errrr okay, not so sure how that's hoi4". In HOI4
## the map is the war: the War screen turns the map into a war map (peoples'
## ground, fronts, hosts) framed on the war, and gives the map back after.
func test_the_war_map_frames_the_war_and_gives_the_map_back()->void:
	var home:Vector2=CivilizationSystem.player_world_origin
	var there:=home+Vector2(200.0,0.0)
	var intel=CivilizationSystem.city_intelligence
	var seen:Dictionary=intel.location_record({"city_id":"test_kaldren","civ_id":civ_id,"name":"Kaldren","position":{"x":there.x,"z":there.y}},5,"scout","test")
	intel.publish("player",seen,5)
	WAR.blood_feud(civ_id,10,"old wrongs")
	var map:=FakeMap.new(); add_child(map)
	map.camera_target=Vector3(home.x,0.0,home.y); map._update_camera()
	var layer:=CanvasLayer.new(); map.add_child(layer)
	var mode:Control=MapMode.new(); mode.terrain=map; layer.add_child(mode)
	mode._process(0.016)
	assert_bool(mode.active).override_failure_message("closed, the map is the map").is_false()
	MilitaryCampaign.open_roster("army")
	await get_tree().process_frame
	mode._process(0.016)
	assert_bool(mode.active).is_true()
	var enemies:Array=mode.scene.enemies
	assert_int(enemies.size()).is_equal(1)
	var e:Dictionary=enemies[0]
	assert_bool((e.there as Vector2).distance_to(there)<0.01).override_failure_message(str(e.there)).is_true()
	assert_bool(bool(e.hot)).is_true()
	# The pointer gets the engine's own numbers: the front's dead and odds,
	# their host as reckoned, ours at home.
	var front_tip:=" / ".join(e.tip_front)
	assert_str(front_tip).contains("Dead:")
	assert_str(front_tip).contains("Odds:")
	assert_str(String((e.tip_host as PackedStringArray)[0])).contains("under arms")
	assert_str(String((mode.scene.levy_tip as PackedStringArray)[0])).starts_with("The watch at home")
	# A click on their ground or host brings their card on the War screen into view.
	await get_tree().process_frame
	assert_bool(mode.show_card(civ_id)).is_true()
	assert_bool(mode.show_card("nobody")).is_false()
	# Our counter counts the army at home as the strip does; the watch is not the army.
	var card:=Bar.levy_card(MilitaryCampaign)
	assert_int(int(mode.scene.levy.troops)).is_equal(int(card.ready)+int(card.drill)+int(card.waiting))
	# The front stands across the way between us, about halfway.
	var front:PackedVector2Array=e.front
	assert_int(front.size()).is_greater_equal(2)
	assert_float(front[front.size()/2].distance_to(home.lerp(there,0.5))).is_less(30.0)
	# Our ground and theirs are both drawn; the towns' cards step aside.
	var owners:Array=mode._owners()
	assert_bool(owners.has(civ_id)).is_true()
	assert_bool(map.city_labels.get_parent().visible).is_false()
	# The view pulls back to take in a town 200 km off.
	assert_float(map.camera.size).is_greater(100.0)
	# Closed again: the cards and the view come back as they were.
	MilitaryCampaign.roster_screen.free()
	await get_tree().process_frame
	mode._process(0.016)
	assert_bool(mode.active).is_false()
	assert_bool(map.city_labels.get_parent().visible).is_true()
	assert_float(map.camera.size).is_equal_approx(12.0,0.01)
	map.free()


## Each people ranges a share of the way to its nearest neighbour, never less
## than a town's own reach nor more than a long march.
func test_each_people_ranges_a_share_of_the_way_to_its_neighbour()->void:
	var towns:=[{"owner":"player","at":Vector2.ZERO},{"owner":"a","at":Vector2(100,0)},{"owner":"b","at":Vector2(0,1000)},{"owner":"c","at":Vector2(0,1010)}]
	var r:=MapMode._ranges(towns)
	assert_float(float(r.player)).is_equal_approx(100.0*MapMode.RANGE_SHARE,0.01)
	assert_float(float(r.a)).is_equal_approx(100.0*MapMode.RANGE_SHARE,0.01)
	assert_float(float(r.b)).is_equal_approx(MapMode.RANGE_MIN_KM,0.01)
	var far:=MapMode._ranges([{"owner":"player","at":Vector2.ZERO},{"owner":"a","at":Vector2(5000,0)}])
	assert_float(float(far.player)).is_equal_approx(MapMode.RANGE_MAX_KM,0.01)


## A host's counter never covers a town's name, nor stands under the War
## screen's strip, column or bar.
func test_a_counter_never_covers_a_name_nor_stands_under_the_war_screen()->void:
	var plate:=Vector2(94,36)
	var bounds:=Rect2(Vector2(96,150),Vector2(900,500))
	var name_rect:=Rect2(Vector2(560,330),Vector2(90,20))
	var spot:=MapMode._clear_spot(Vector2(600,380),plate,[name_rect],bounds)
	var placed:=Rect2(spot-plate*0.5,plate)
	assert_bool(placed.intersects(name_rect)).is_false()
	assert_bool(bounds.encloses(placed)).is_true()
	# A town right under the strip: its counter goes beside or below, inside.
	var high:=MapMode._clear_spot(Vector2(500,160),plate,[],bounds)
	assert_bool(bounds.encloses(Rect2(high-plate*0.5,plate))).is_true()

## A people gathering every spear against us is on the War screen, feud or
## no feud, and its card leads with the days until it marches
## (world_answer.gd).
func test_a_people_arming_against_us_leads_its_card_with_the_march()->void:
	var answer:=preload("res://scripts/world_answer.gd")
	var ledger:=preload("res://scripts/hud/war_ledger_model.gd")
	var day:=int(GameState.elapsed_days)
	answer._begin_arming(civ_id,day,{"why_all_in":"they resent us"})
	var entry:Dictionary={}
	for e:Dictionary in ledger.entries(day):
		if String(e.civ_id)==civ_id: entry=e
	assert_bool(entry.is_empty()).is_false()
	var left:=int(answer.arming(civ_id).march)-day
	assert_int(int(entry.arming_days)).is_equal(left)
	var said:=Board.now_short(entry)
	assert_bool(bool(said.danger)).is_true()
	assert_str(String(said.text)).contains("Gathering every spear")
	assert_str(String(said.text)).contains("%d days" % left)
