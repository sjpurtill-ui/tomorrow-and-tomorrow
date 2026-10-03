extends GdUnitTestSuite
## "Fighters here — none of its own": the town page told the player our other
## towns stood undefended, while in battle each fights with its own watch; the
## map badge used a third count, home had none, and an open card drew its
## badge twice. Now one count: a town's page, its map badge, its battle and
## a stranger's scout muster the same defenders: the watch at home, each
## town's share of the home guard and its townsfolk who rise
## (civilization_combat.gd guard_ledger). KEEPING WATCH IS THE MILITARY
## (watch_military.gd): the watch is everyone under arms; its home guard is
## spread over home and the towns by their people, and the rest stand at
## home until the war council sends them out in bands. The map badge shows
## that count in its two parts, never as one sum that reads as soldiers:
## those keeping watch, and in lighter ink "+N" townsfolk who would rise.

const Combat:=preload("res://scripts/civilization_combat.gd")
const Model:=preload("res://scripts/hud/own_town_model.gd")
const Labels:=preload("res://scripts/hud/city_labels.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

const TOWN:="settlement_002"

## The map layer with its drawing calls recorded instead of drawn.
class Probe extends "res://scripts/hud/city_labels.gd":
	var frames:Array=[]
	var opened:Array=[]
	func _draw_works()->void:pass
	func _draw_leader(_card:Dictionary,_box:Rect2,_anchor:Vector2,_fade:float=1.0)->void:pass
	func _draw_frame(card:Dictionary,_box:Rect2,_solid:bool,_fade:float=1.0)->void:frames.append(String(card.id))
	func _draw_card(card:Dictionary,_box:Rect2,solid:bool=false)->void:opened.append([String(card.id),solid])

var _processing:Dictionary={}


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]:_processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(6062);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GameState.ensure_population_total(400);GameState.housing_capacity=500
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];GameState.settlement_name="SEANSTONE"
	SettlementModel.ensure_founded()
	GameState.population_allocations["Defense"]=40
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	var second:Dictionary={"id":TOWN,"sequence":2,"primary":false,"name":"Valebridge","position":Vector2(100,0),"population_share":.25,"founded_day":0,"status":"established","territory_context":{},"environment_profile":{}}
	GameState.player_settlements.append(second);GameState.next_player_settlement_id=3;SettlementModel._ensure_city_resources(second)


func after_test()->void:
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))


func _home_id()->String:
	for city:Dictionary in GameState.player_settlements:
		if bool(city.get("primary",false)):return String(city.id)
	return ""


## The watch at home, drilled: `count` keep watch (the Defense work), all at
## home in one formation, and `split` of them the home guard.
func _levy(count:int,split:float=0.5)->void:
	var sim=MilitaryCampaign.simulator
	var sets:int=sim.equipment_required_for_weapon("improvised",count)
	var army:=MilitaryCampaign._empty_home_army()
	army["formations"]=[{"id":1,"unit":"levy","weapon":"improvised","count":count,"authorized_count":count,"equipment":sets,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.6,"experience":0.1,"personnel_condition":1.0}]
	army["troops"]=count
	MilitaryCampaign.home_army=army
	GameState.population_allocations["Defense"]=count
	MilitaryCampaign.set_watch_split(split)


## The forty keeping watch join it at home (the war leader's keeping).
func _fill()->void:
	MilitaryCampaign.keep_watch()


## The map card of one of our towns, measured as the layer measures it. The
## label carries no id of its own, as home's never does.
func _card(id:String,title:String)->Dictionary:
	var label:=Label3D.new();label.text="%s  •  100" % title
	var card:=Labels._measure_card(label,{},false,"",false,T.voice_font(),Rect2(0,0,1600,900),{},id)
	label.free()
	return card


## Who would stand in one town of ours, part by part (the guard ledger).
func _parts(id:String)->Dictionary:
	return Combat.guard_ledger().get(id,{"watch":0,"rise":0})


## The townsfolk who would rise in all our towns that keep a guard: one in
## ten of the grown people not on defence work or under arms, by the share
## of the people living in those towns.
func _rise_expected(keeping_share:float=1.0)->int:
	var serving:=maxi(int(GameState.population_allocations.get("Defense",0)),int(MilitaryCampaign._mobilized_count()))
	var adults:=maxf(0.0,float(GameState.population_cohorts.get("working_age",0.0))-float(Combat._away(GameState))-float(serving))
	return roundi(Combat.RISE_SHARE*adults*keeping_share)


func _rises()->int:
	var total:=0
	for id in Combat.guard_ledger():total+=int(Combat.guard_ledger()[id].rise)
	return total


func test_a_second_town_shows_the_watch_and_the_townsfolk_who_fight_there()->void:
	# Forty keep watch, half of them the home guard. A quarter of the people
	# live there: a quarter of the twenty, and a quarter of the townsfolk who
	# rise.
	_fill()
	MilitaryCampaign.set_watch_split(0.5)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(40)
	var parts:=_parts(TOWN)
	assert_int(int(parts.watch)).is_equal(5)
	assert_int(int(parts.rise)).is_greater(0)
	assert_int(_rises()).is_equal(_rise_expected())
	var fights:=int(Combat.town_watch(TOWN).troops)
	assert_int(fights).is_equal(int(parts.watch)+int(parts.rise))
	var strong:=Model.strength(false,TOWN)
	assert_int(int(strong.defenders)).is_equal(fights)
	var facts:={"strength":strong}
	var row:=Model.row_for("garrison",facts)
	assert_int(int(row.number)).is_equal(fights)
	assert_str(String(row.value)).is_equal("5 on watch, %d would take up arms" % int(parts.rise))
	assert_str(String(row.value)).not_contains("none of its own")
	# Plain words: who they are, and that the trained stay home.
	assert_str(String(row.meaning)).contains("townsfolk who take up arms").contains("Seanstone").not_contains("levy at home guards")
	row["marks"]=[]
	var tip:=Model._tip(row,facts)
	assert_str(tip).contains("about 1 in 10 of the town's grown people take up arms beside the watch. They are untrained.")
	# The map badge is the same count, and the battle's, and a scout's, in
	# its two parts: the five on watch, then the townsfolk.
	assert_dict(Labels.guard_parts(TOWN)).is_equal({"watch":5,"rise":int(parts.rise),"bands":0})
	var card:=_card(TOWN,"Valebridge")
	assert_int(int(card.badge)).is_equal(5)
	assert_int(int(card.rise)).is_equal(int(parts.rise))
	assert_int(int(card.badge)+int(card.rise)).is_equal(fights)
	assert_float(float(CivilizationSystem.city_intelligence.truth(TOWN).values.garrison)).is_equal(float(fights))
	# The drawing puts them at the gate.
	var sketch:=Model.sketch_data({"id":TOWN,"population":100,"places":120,"broken":0.0,"food_reported":false,"food_days":-1.0,"material":0.0,"logistics":0.0,"water":{},"completed":[],"strength":strong},"")
	assert_float(float(sketch.fields.garrison.low)).is_equal(float(fights))


func test_the_townsfolk_rise_untrained_one_in_ten_of_those_not_already_serving()->void:
	assert_float(Combat.RISE_SHARE).is_equal(0.10)
	# Two blocks fight side by side: the home guard posted there, drilled as
	# the watch at home is and carrying its share of the watch's arms, and the
	# townsfolk with none and what comes to hand (the combat simulator holds
	# any block at its least drill, 0.25, at the least).
	_levy(40)
	var parts:=_parts(TOWN)
	assert_float(Combat.guard_drill()).is_equal_approx(0.6,0.0001)
	var blocks:Array=Combat.town_watch(TOWN).formations
	assert_int(blocks.size()).is_equal(2)
	var guard:Dictionary=blocks[0]
	assert_int(int(guard.count)).is_equal(int(parts.watch))
	assert_float(float(guard.training)).is_equal_approx(Combat.guard_drill(),0.0001)
	# The watch at home is fully armed here, and so is the guard it posted.
	assert_int(int(guard.equipment)).is_equal(int(guard.equipment_required))
	var rise:Dictionary=blocks[1]
	assert_int(int(rise.count)).is_equal(int(parts.rise))
	assert_float(float(rise.training)).is_equal_approx(clampf(Combat.RISE_TRAINING,0.25,1.25),0.0001)
	assert_int(int(rise.equipment)).is_equal(0)
	assert_str(String(rise.weapon)).is_equal("improvised")
	# Those called up beyond the Defense share are under arms already: fewer
	# townsfolk are left to rise.
	var before:=_rises()
	MilitaryCampaign.aggregate_recruits=60
	assert_int(_rises()).is_equal(_rise_expected())
	assert_int(_rises()).is_less(before)
	# A town held or left empty raises no one for the others.
	MilitaryCampaign.aggregate_recruits=0
	SettlementModel.settlement_record(TOWN)["status"]="abandoned"
	assert_int(int(_parts(TOWN).rise)).is_equal(0)
	assert_int(_rises()).is_equal(_rise_expected(0.75))


func test_a_band_marching_out_is_still_under_arms_not_the_watch()->void:
	_levy(40)
	var home:=_home_id()
	# Forty keep watch, twenty of them the home guard over home and the town.
	assert_int(_sum(Combat.watch_ledger())).is_equal(20)
	var rise:=_rises()
	var home_before:=Combat.defenders(home)
	var town_before:=Combat.defenders(TOWN)
	var formed:=MilitaryCampaign.create_field_army(20)
	assert_bool(formed.has("error")).override_failure_message(str(formed)).is_false()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(20)
	# The twenty who marched are under arms still: the home guard and the
	# townsfolk who rise are the same, and home stands with twenty fewer.
	assert_int(_sum(Combat.watch_ledger())).is_equal(20)
	assert_int(_rises()).is_equal(rise)
	assert_int(Combat.defenders(TOWN)).is_equal(town_before)
	assert_int(Combat.defenders(home)).is_equal(home_before-20)
	assert_int(int(MilitaryCampaign._home_defense_force(false).troops)).is_equal(home_before-20)
	# The hurt, the scattered and the taken are no guard: only those standing
	# at home are.
	var standing:=int(MilitaryCampaign.home_army.troops)
	MilitaryCampaign._home_guard_losses(5,"wounded_pool")
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(standing-5)
	assert_int(_sum(Combat.watch_ledger())).is_equal(standing-5)
	# Those away from home (caravans, convoys, scholars) do not rise.
	assert_int(_rises()).is_equal(_rise_expected())


func test_a_landing_hits_the_guard_where_it_stands()->void:
	var AN:=preload("res://scripts/air_naval_consequences.gd")
	_levy(40)
	var home:=_home_id()
	# At Valebridge its share of the home guard and its townsfolk stand: its
	# own people fall, and the guard's share comes off the watch at home.
	var people:=GameState.population_total
	var levy:=int(MilitaryCampaign.home_army.troops)
	var here:=_parts(TOWN)
	var share:=float(int(here.watch))/float(int(here.watch)+int(here.rise))
	var town:=AN.strike_town_guard(TOWN,6)
	assert_int(int(town.hit)).is_equal(6)
	assert_int(int(town.killed)).is_equal(2)
	assert_int(people-GameState.population_total).is_equal(2)
	assert_int(levy-int(MilitaryCampaign.home_army.troops)).is_equal(roundi(2.0*share)+roundi(4.0*share))
	# At home the hits fall on those free for the bands, and on home's guard
	# and townsfolk by their share of those who stood.
	levy=int(MilitaryCampaign.home_army.troops)
	var parts:=Combat.guard_of(SettlementModel.settlement_record(home))
	var stood:=int(parts.trained)+int(parts.watch)+int(parts.rise)
	people=GameState.population_total
	var at_home:=AN.strike_town_guard(home,20)
	assert_int(int(at_home.hit)).is_equal(20)
	var trained_hit:=roundi(20.0*float(int(parts.trained))/float(stood))
	var militia_hit:=20-trained_hit
	var militia_killed:=roundi(float(militia_hit)*.35)
	var guard_share:=float(int(parts.watch))/float(int(parts.watch)+int(parts.rise))
	assert_int(levy-int(MilitaryCampaign.home_army.troops)).is_equal(trained_hit+roundi(float(militia_killed)*guard_share)+roundi(float(militia_hit-militia_killed)*guard_share))
	assert_int(people-GameState.population_total).is_equal(int(at_home.killed))
	# No more are hit than stood there.
	assert_int(int(AN.strike_town_guard(TOWN,10_000).hit)).is_equal(Combat.defenders(TOWN))


func test_a_town_with_no_one_on_watch_still_has_its_townsfolk()->void:
	GameState.population_allocations["Defense"]=0
	var parts:=_parts(TOWN)
	assert_int(int(parts.watch)).is_equal(0)
	var row:=Model.row_for("garrison",{"strength":Model.strength(false,TOWN)})
	assert_int(int(row.number)).is_equal(int(parts.rise))
	assert_str(String(row.value)).is_equal("%d would take up arms" % int(parts.rise))
	# The badge never shows the townsfolk as a bare count: none on watch,
	# then "+N", and its words say no one keeps watch.
	assert_int(int(Labels.guard_parts(TOWN).watch)).is_equal(0)
	var card:=_card(TOWN,"Valebridge")
	assert_int(int(card.badge)).is_equal(0)
	assert_int(int(card.rise)).is_equal(int(parts.rise))
	assert_str(String(card.badge_tip)).starts_with("No one keeps watch here. If the town is attacked, about %d of its grown townsfolk" % int(parts.rise))
	# Every grown person already called up: nobody is left to rise.
	MilitaryCampaign.aggregate_recruits=100_000
	assert_dict(Combat.town_watch(TOWN)).is_empty()
	assert_str(String(Model.row_for("garrison",{"strength":Model.strength(false,TOWN)}).value)).is_equal("no one")
	# Nobody at all: no badge.
	card=_card(TOWN,"Valebridge")
	assert_int(int(card.badge)+int(card.rise)).is_equal(0)
	assert_str(String(card.badge_tip)).is_empty()


func test_two_on_watch_read_as_two_not_as_seven()->void:
	# The player's question: "why do these show 7 and 3 when I only have 2
	# people assigned to keeping watch?" Two keep watch, both at home; the
	# split keeps a fifth of the watch as the home guard, none of two, so both
	# are free for the bands and stand at home until a general takes them.
	_levy(2,0.2)
	var home:=_home_id()
	var at_home:=_parts(home);var there:=_parts(TOWN)
	assert_int(int(at_home.watch)).is_equal(0)
	assert_int(int(there.watch)).is_equal(0)
	assert_int(int(at_home.rise)).is_greater(0)
	assert_int(int(there.rise)).is_greater(0)
	# Home: "2 +N", never the sum; Valebridge: "0 +N", never a bare N.
	var ours:=_card(home,"SEANSTONE")
	assert_int(int(ours.badge)).is_equal(2)
	assert_int(int(ours.rise)).is_equal(int(at_home.rise))
	assert_int(int(ours.badge)+int(ours.rise)).is_equal(Combat.defenders(home))
	var town:=_card(TOWN,"Valebridge")
	assert_int(int(town.badge)).is_equal(0)
	assert_int(int(town.rise)).is_equal(int(there.rise))
	assert_int(int(town.rise)).is_equal(Combat.defenders(TOWN))
	# Every town's watch adds up to the two keeping watch.
	var on_watch:=0
	for city:Dictionary in GameState.player_settlements:on_watch+=int(Labels.guard_parts(String(city.id)).watch)
	assert_int(on_watch).is_equal(2)
	# Its words, with the engine's numbers.
	assert_str(String(ours.badge_tip)).is_equal("2 keep watch here. If the town is attacked, about %d of its grown townsfolk would take up whatever is at hand and fight beside them (1 in 10 of the grown people). None of them is kept as the home guard: a general may lead them away in a band." % int(at_home.rise))
	assert_str(String(town.badge_tip)).is_equal("No one keeps watch here. If the town is attacked, about %d of its grown townsfolk would take up whatever is at hand and fight (1 in 10 of the grown people)." % int(there.rise))
	# The town page says the same, in the same words.
	assert_str(String(Model.row_for("garrison",{"strength":Model.strength(true,home)}).value)).is_equal("2 on watch, %d would take up arms" % int(at_home.rise))
	assert_str(String(Model.row_for("garrison",{"strength":Model.strength(false,TOWN)}).value)).is_equal("%d would take up arms" % int(there.rise))
	var strong:=Model.strength(true,home)
	assert_str(Model._tip(Model.row_for("garrison",{"strength":strong}),{"strength":strong})).contains("None of the 2 on watch is kept as the home guard")


func test_a_town_someone_else_holds_keeps_no_guard_of_ours()->void:
	SettlementModel.settlement_record(TOWN)["occupied_by"]="civ_03"
	assert_int(int(Model.strength(false,TOWN).defenders)).is_equal(0)
	assert_int(Combat.defenders(TOWN)).is_equal(0)
	assert_dict(Combat.town_watch(TOWN)).is_empty()
	assert_dict(Labels.guard_parts(TOWN)).is_equal(Labels.NO_GUARD)
	assert_str(String(Model.row_for("garrison",{"strength":Model.strength(false,TOWN)}).value)).is_equal("none of ours")


## The town's drawing, from the page's own figures.
func _sketch(strong:Dictionary)->Dictionary:
	return Model.sketch_data({"id":"","population":100,"places":120,"broken":0.0,"food_reported":false,"food_days":-1.0,"material":0.0,"logistics":0.0,"water":{},"completed":[],"strength":strong},"")


func test_home_taken_by_another_people_shows_none_of_ours_everywhere()->void:
	# Home taken (siege_recovery.capture marks the home record occupied).
	_levy(12)
	var home:=_home_id()
	SettlementModel.settlement_record(home)["occupied_by"]="civ_03"
	assert_int(Combat.defenders(home)).is_equal(0)
	for id:String in [home,""]:
		var strong:=Model.strength(true,id)
		assert_int(int(strong.defenders)).override_failure_message(id).is_equal(0)
		var row:=Model.row_for("garrison",{"strength":strong})
		assert_int(int(row.number)).is_equal(0)
		assert_str(String(row.value)).is_equal("none of ours")
		assert_bool((_sketch(strong).fields as Dictionary).has("garrison")).is_false()
	assert_dict(Labels.guard_parts(home)).is_equal(Labels.NO_GUARD)
	var card:=_card(home,"SEANSTONE")
	assert_int(int(card.badge)+int(card.rise)).is_equal(0)


func test_the_capital_is_spelled_as_the_map_spells_it()->void:
	GameState.settlement_name="Ash-ford by the water"
	var meaning:=String(Model.row_for("garrison",{"strength":Model.strength(false,TOWN)}).meaning)
	# The map letters home from its upper-cased name (local_terrain
	# _settlement_display_name, then city_labels chart_name).
	var on_map:=Labels.chart_name(GameState.settlement_name.to_upper())
	assert_str(on_map).is_equal("Ash-Ford By The Water")
	assert_str(meaning).contains("stay at %s unless" % on_map)
	GameState.settlement_name=""
	assert_str(String(Model.row_for("garrison",{"strength":Model.strength(false,TOWN)}).meaning)).contains("stay at home unless")


func test_scouted_towns_are_counted_like_for_like_without_a_caveat()->void:
	# A scout counts a stranger's town as its battle musters it, as ours is
	# counted: the bars compare like with like and need no warning.
	var facts:={"strength":Model.strength(false,TOWN)}
	var row:=Model.row_for("garrison",facts)
	row["marks"]=[{"name":"Flintwick","low":0.0,"high":2.0,"words":"about 1","seen":"a season ago"}]
	assert_str(Model._tip(row,facts)).not_contains("Scouts count")


func test_the_map_reads_every_guard_in_one_pass_and_again_only_on_change()->void:
	_levy(40)
	var home:=_home_id()
	var probe:Probe=auto_free(Probe.new())
	var guards:Dictionary=probe._guards()
	assert_dict(guards[home]).is_equal(Labels.guard_parts(home))
	assert_dict(guards[TOWN]).is_equal(Labels.guard_parts(TOWN))
	# Forty keep watch, twenty of them the home guard: a quarter of the guard
	# in Valebridge beside a quarter of the townsfolk; at home the other
	# fifteen of the guard and the twenty free for the bands.
	assert_dict(guards[TOWN]).is_equal({"watch":5,"rise":int(_parts(TOWN).rise),"bands":0})
	assert_dict(guards[home]).is_equal({"watch":20+15,"rise":int(_parts(home).rise),"bands":20})
	# Unchanged: the same reading, not a new one.
	assert_bool(is_same(probe._guards(),guards)).is_true()
	# The home guard changes while the day stands still: read again.
	MilitaryCampaign.set_watch_split(1.0)
	assert_int(int(probe._guards()[TOWN].watch)).is_equal(10)
	assert_int(int(probe._guards()[home].watch)).is_equal(30)
	assert_int(int(probe._guards()[home].bands)).is_equal(0)


func test_home_shows_its_levy_watch_and_townsfolk_as_its_battle_musters_them()->void:
	_levy(40)
	var home:=_home_id()
	var parts:=_parts(home)
	# Home's battle: the twenty free for the bands, home's share of the twenty
	# in the home guard (three in four of the people live at home): 15, and
	# its townsfolk. The five posted in Valebridge stand there.
	assert_int(int(parts.watch)).is_equal(15)
	var musters:=int(MilitaryCampaign._home_defense_force(false).troops)
	assert_int(musters).is_equal(20+15+int(parts.rise))
	assert_int(Combat.defenders(home)).is_equal(musters)
	var strong:=Model.strength(true,home)
	assert_int(int(strong.defenders)).is_equal(musters)
	var row:=Model.row_for("garrison",{"strength":strong})
	assert_int(int(row.number)).is_equal(musters)
	# Those keeping watch and the townsfolk apart, never one count of
	# "fighters" that reads as soldiers.
	assert_str(String(row.value)).is_equal("35 on watch, %d would take up arms" % int(parts.rise))
	assert_str(String(row.note)).is_equal("20 for the bands")
	assert_str(Model._tip(row,{"strength":strong})).contains("Of the 35 on watch, 20 are free for the bands and 15 are the home guard.")
	# The Military ledger's garrison at home, and a scout's count, are the same muster.
	assert_int(int(MilitaryCampaign.settlement_defense_snapshot().garrison_personnel)).is_equal(musters)
	assert_float(float(CivilizationSystem.city_intelligence.truth(home).values.garrison)).is_equal(float(musters))
	# Home's badge appears, though its label carries no id of its own: the
	# thirty-five on watch, then its townsfolk.
	var card:=_card(home,"SEANSTONE")
	assert_int(int(card.badge)).is_equal(35)
	assert_int(int(card.rise)).is_equal(int(parts.rise))
	assert_int(int(card.badge)+int(card.rise)).is_equal(musters)
	assert_str(String(card.badge_tip)).contains("15 of them are the home guard and stay; a general may lead the other 20 away in a band.")
	# With no home guard kept, everyone keeping watch is for the bands and
	# stands at home until sent; the towns keep only their townsfolk.
	_levy(55,0.0)
	var rise:=int(_parts(home).rise)
	assert_int(int(_parts(home).watch)).is_equal(0)
	assert_int(int(_parts(TOWN).watch)).is_equal(0)
	assert_dict(Labels.guard_parts(home)).is_equal({"watch":55,"rise":rise,"bands":55})
	assert_int(int(MilitaryCampaign._home_defense_force(false).troops)).is_equal(55+rise)
	assert_str(String(Model.row_for("garrison",{"strength":Model.strength(true,home)}).value)).is_equal("55 on watch, %d would take up arms" % rise)


func test_an_open_card_fits_its_name_and_badge_and_draws_one_badge()->void:
	# No one on watch there yet: "0 +N", the townsfolk alone.
	var card:=_card(TOWN,"Valebridge")
	assert_int(int(card.badge)+int(card.rise)).is_greater(0)
	# The open card is at least as wide as the name tag with its badge.
	assert_float(float((card.detail as Vector2).x)).is_greater_equal(float(card.name_width))
	var probe:Probe=auto_free(Probe.new())
	probe.last_bounds=Rect2(0,0,1600,900)
	var tag:={"id":TOWN,"compact":true,"rect":Rect2(Vector2(400,300),Vector2(card.name_width,30)),"anchor":Vector2(390,340),"detail_extent":card.detail,"lines":card.lines,"badge":card.badge,"color":Color.WHITE,"flag":null}
	var other:={"id":"other","compact":true,"rect":Rect2(Vector2(800,300),Vector2(90,30)),"anchor":Vector2(790,340),"detail_extent":Vector2(135,60),"lines":["Other"],"badge":0,"color":Color.WHITE,"flag":null}
	probe.cards.assign([tag,other])
	probe.pinned_id=TOWN
	probe._draw()
	# The open town is drawn once, as its card; its name tag is not under it.
	assert_array(probe.frames).contains_exactly(["other"])
	assert_array(probe.opened).contains_exactly([[TOWN,true]])
	# The badge stays where it was on the name tag when the card opens under
	# the pointer, at the end of the name line.
	tag["rise"]=card.rise;tag["name_width"]=card.name_width
	assert_bool(Labels.badge_rect(tag,probe.detail_rect(tag))==Labels.badge_rect(tag,tag.rect)).is_true()


# --------------------------------------------------------------------------
# One guard ledger: no one stands in two places
# --------------------------------------------------------------------------

## Five more towns of ours: seven in all, home keeping two in five.
func _seven_towns()->Array[String]:
	var ids:Array[String]=[_home_id(),TOWN]
	var shares:=[.10,.08,.07,.05,.05]
	for i in shares.size():
		var id:="settlement_%03d" % (i+3)
		var town:Dictionary={"id":id,"sequence":i+3,"primary":false,"name":"Town %d" % (i+3),"position":Vector2(100+40*i,60),"population_share":shares[i],"founded_day":0,"status":"established","territory_context":{},"environment_profile":{}}
		GameState.player_settlements.append(town);SettlementModel._ensure_city_resources(town)
		ids.append(id)
	GameState.next_player_settlement_id=8
	return ids


func _sum(values:Dictionary)->int:
	var total:=0
	for key in values:total+=int(values[key])
	return total


func test_the_watch_and_the_townsfolk_are_shared_out_once_among_seven_towns()->void:
	var ids:=_seven_towns()
	var home:=_home_id()
	# Sixty keep watch, 48 of them the home guard, each in the town they live
	# in; twelve stand at home for the bands.
	_levy(60,0.8)
	var ledger:=Combat.watch_ledger()
	assert_int(_sum(ledger)).is_equal(48)
	# The townsfolk who rise: one in ten of the grown people not serving.
	var rise:=_rises()
	assert_int(rise).is_equal(_rise_expected())
	var by_town:=Combat.defenders_by_town()
	# All the towns together: the sixty on defence and the townsfolk, never more.
	assert_int(_sum(by_town)).is_equal(60+rise)
	assert_int(int(by_town[home])).is_equal(12+int(ledger[home])+int(_parts(home).rise))
	# Home keeps two in five of the watch, Valebridge one in four.
	assert_int(int(ledger[home])).is_between(19,20)
	assert_int(int(ledger[TOWN])).is_equal(12)
	# Home's battle, card, badge and a scout's count: the same number.
	var intel=CivilizationSystem.city_intelligence
	assert_int(int(MilitaryCampaign._home_defense_force(false).troops)).is_equal(int(by_town[home]))
	assert_int(int(Model.strength(true,home).defenders)).is_equal(int(by_town[home]))
	assert_int(int(Labels.guard_parts(home).watch)+int(Labels.guard_parts(home).rise)).is_equal(int(by_town[home]))
	assert_float(float(intel.truth(home).values.garrison)).is_equal(float(by_town[home]))
	# Every other town's battle, card, badge and a scout's count: its share.
	for id:String in ids.slice(1):
		var share:=int(by_town[id])
		assert_int(share).override_failure_message(id).is_equal(int(_parts(id).watch)+int(_parts(id).rise))
		var fights:=int(Combat.town_watch(id).get("troops",0))
		assert_int(fights).override_failure_message(id).is_equal(share)
		assert_int(int(Model.strength(false,id).defenders)).override_failure_message(id).is_equal(share)
		assert_dict(Labels.guard_parts(id)).override_failure_message(id).is_equal({"watch":int(_parts(id).watch),"rise":int(_parts(id).rise),"bands":0})
		var card:=_card(id,"Town")
		assert_int(int(card.badge)).override_failure_message(id).is_equal(int(_parts(id).watch))
		assert_int(int(card.rise)).override_failure_message(id).is_equal(int(_parts(id).rise))
		assert_float(float(intel.truth(id).values.garrison)).override_failure_message(id).is_equal(float(share))
	# No home guard kept: no one is posted in the towns, and the townsfolk
	# still rise.
	_levy(75,0.0)
	assert_int(_sum(Combat.watch_ledger())).is_equal(0)
	assert_int(_sum(Combat.defenders_by_town())).is_equal(75+_rises())
	assert_int(int(Combat.defenders_by_town()[TOWN])).is_equal(int(_parts(TOWN).rise))
	assert_int(int(_parts(TOWN).rise)).is_greater(0)


func test_a_town_left_or_taken_gives_its_watch_to_the_towns_still_ours()->void:
	_seven_towns()
	_levy(60,0.8)
	SettlementModel.settlement_record("settlement_003")["status"]="abandoned"
	SettlementModel.settlement_record("settlement_004")["occupied_by"]="civ_03"
	var ledger:=Combat.watch_ledger()
	assert_int(int(ledger["settlement_003"])).is_equal(0)
	assert_int(int(ledger["settlement_004"])).is_equal(0)
	assert_int(_sum(ledger)).is_equal(48)
	# Their townsfolk do not rise for the others.
	assert_int(int(_parts("settlement_003").rise)).is_equal(0)
	assert_int(int(_parts("settlement_004").rise)).is_equal(0)
	assert_int(_rises()).is_equal(_rise_expected(1.0-.10-.08))


# --------------------------------------------------------------------------
# What scouts count: the same defenders, for every people
# --------------------------------------------------------------------------

func test_our_towns_are_counted_by_a_strangers_scout_as_their_battle_musters_them()->void:
	_seven_towns()
	_levy(60,0.8)
	var intel=CivilizationSystem.city_intelligence
	var guards:=Combat.defenders_by_town()
	for city:Dictionary in GameState.player_settlements:
		var id:=String(city.id)
		var truth:Dictionary=intel.truth(id)
		assert_float(float(truth.values.garrison)).override_failure_message(id).is_equal(float(guards[id]))
	# A town another people holds is theirs to count, not ours.
	SettlementModel.settlement_record(TOWN)["occupied_by"]="civ_03"
	assert_bool((intel.truth(TOWN).values as Dictionary).has("garrison")).is_false()


func test_a_rivals_other_town_is_counted_fought_and_landed_on_by_its_guard()->void:
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	WorldSimulation.actors.alpha.controller="manual"
	var local:="settlement_002"
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.state.ensure_population_total(1000)
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.settlements.ensure_founded()
		var second:Dictionary={"id":local,"sequence":2,"primary":false,"name":"Alphaford","position":Vector2(60,0),"population_share":.3,"founded_day":0,"status":"established","territory_context":{},"environment_profile":{}}
		WorldSimulation.state.player_settlements.append(second);WorldSimulation.state.next_player_settlement_id=3;WorldSimulation.settlements._ensure_city_resources(second)
		WorldSimulation.state.population_allocations["Defense"]=50
		WorldSimulation.military.home_army=WorldSimulation.military._empty_home_army()
		# The fifty keeping watch stand at home, all of them the home guard.
		WorldSimulation.military.keep_watch()
		WorldSimulation.military.set_watch_split(1.0)
	)
	var civ:=CivilizationSystem.civilizations[0].duplicate(true)
	civ.id="alpha";civ.name="Alpha"
	WorldSimulation.scoped("alpha",func()->void:WorldSimulation.project(civ))
	CivilizationSystem.civilizations[0]=civ
	var parts:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:return Combat.guard_ledger().get(local,{}))
	# Fifty keep their watch, all the home guard; three in ten of their people
	# in Alphaford, and three in ten of their townsfolk who rise.
	assert_int(int(parts.watch)).is_equal(15)
	assert_int(int(parts.rise)).is_greater(0)
	var guard:=int(parts.watch)+int(parts.rise)
	var region_id:=""
	for region:Dictionary in civ.strategic_regions:
		if String(region.get("local_city_id",""))==local:region_id=String(region.id)
	assert_str(region_id).is_not_empty()
	# Our scouts' truth of their town is its guard, as their battle musters it.
	var truth:Dictionary=CivilizationSystem.city_intelligence.truth(region_id)
	assert_float(float(truth.values.garrison)).is_equal(float(guard))
	var fights:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:return Combat.town_watch(local))
	assert_int(int(fights.troops)).is_equal(guard)
	# A landing there meets the same guard on its beach.
	var army:={"army_id":1,"name":"Landing force","troops":200,"formations":[{"count":200}]}
	var landed:Dictionary=preload("res://scripts/air_naval_consequences.gd").opposed_landing(army,{"destination_owner":"alpha","destination_id":region_id},.5)
	assert_int(int(landed.defenders)).is_equal(roundi(float(guard)*.3+200.0*.02))
	# Their scouts' truth of our Valebridge is ours, read in our own scope.
	assert_float(float(CivilizationSystem.city_intelligence.truth(TOWN).values.garrison)).is_equal(float(Combat.defenders(TOWN)))
	# Our scouts see how many of them are no soldiers: the townsfolk only, the
	# home guard being their watch, drilled and armed; the stated odds arm the
	# townsfolk as the battle does: a levy with what comes to hand.
	assert_float(float(truth.values.garrison_untrained)).is_equal(float(int(parts.rise)))
	var intel=CivilizationSystem.city_intelligence
	var day:=int(GameState.elapsed_days)
	intel.publish("player",intel.capture("player",region_id,.9,day,"test","t"),day)
	var estimate:Dictionary=preload("res://scripts/court_war_orders.gd").enemy_estimate(region_id)
	assert_bool(bool(estimate.known)).is_true()
	assert_float(float(estimate.untrained)).is_equal_approx(snappedf(float(int(parts.rise))/float(guard),0.1),0.051)
	WorldSimulation.context_provider=Callable()


func test_the_stated_odds_arm_the_townsfolk_as_the_battle_does()->void:
	var Odds:=preload("res://scripts/war_odds.gd")
	_levy(12)
	var ours:Array=MilitaryCampaign.home_army.formations
	# Forty men drilled as a garrison against forty townsfolk with what comes
	# to hand: the townsfolk are far weaker.
	var soldiers:=Odds.of(MilitaryCampaign.home_army,ours,12,40.0,0.0,[],"",true,1.0,0.0)
	var townsfolk:=Odds.of(MilitaryCampaign.home_army,ours,12,40.0,0.0,[],"",true,1.0,1.0)
	assert_float(float(townsfolk.raw)).is_greater(float(soldiers.raw))
	var block:=Odds.townsfolk(9)
	assert_str(String(block.weapon)).is_equal("improvised")
	assert_int(int(block.equipment)).is_equal(0)
	assert_float(float(block.training)).is_equal(Combat.RISE_TRAINING)


func test_the_defence_page_counts_the_guard_and_names_the_townsfolk_apart()->void:
	var Impact:=preload("res://scripts/task_impact.gd")
	# Nobody on defence work and no levy: home has no guard, though its
	# townsfolk would still rise.
	GameState.population_allocations["Defense"]=0
	var rows:={}
	for line:Dictionary in Impact.defense().lines:rows[String(line.label)]=line
	var defense:=MilitaryCampaign.settlement_defense_snapshot()
	assert_int(int(defense.garrison_guard)).is_equal(0)
	assert_int(int(defense.garrison_townsfolk)).is_greater(0)
	assert_str(String(rows["Guard at home"].value)).starts_with("0 of ")
	assert_str(String(rows["Guard at home"].tone)).is_equal("bad")
	assert_str(String(rows["Guard at home"].words)).not_contains("The watch is the town's guard")
	assert_str(String(rows["Townsfolk who would fight"].words)).contains("1 in 10")
	assert_float(float(defense.garrison_coverage)).is_equal(0.0)
	# The watch at home is the guard; the townsfolk are not.
	_levy(40)
	defense=MilitaryCampaign.settlement_defense_snapshot()
	assert_int(int(defense.garrison_guard)).is_equal(int(defense.garrison_trained)+int(defense.garrison_watch))
	assert_int(int(defense.garrison_guard)).is_equal(40-Combat.posted_away())
	assert_int(int(defense.garrison_personnel)).is_equal(int(defense.garrison_guard)+int(defense.garrison_townsfolk))
