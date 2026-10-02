extends GdUnitTestSuite
## "Fighters here — none of its own": the town page told the player our other
## towns stood undefended, while in battle each fights with its own watch; the
## map badge used a third count, home had none, and an open card drew its
## badge twice. Now one count: a town's page, its map badge and its battle
## muster the same defenders (civilization_combat.gd defenders/watch_count).

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


## Home's levy, trained and drilled: `count` levymen in one formation.
func _levy(count:int)->void:
	var sim=MilitaryCampaign.simulator
	var sets:int=sim.equipment_required_for_weapon("improvised",count)
	var army:=MilitaryCampaign._empty_home_army()
	army["formations"]=[{"id":1,"unit":"levy","weapon":"improvised","count":count,"authorized_count":count,"equipment":sets,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.6,"experience":0.1,"personnel_condition":1.0}]
	army["troops"]=count
	MilitaryCampaign.home_army=army


## The map card of one of our towns, measured as the layer measures it. The
## label carries no id of its own, as home's never does.
func _card(id:String,title:String)->Dictionary:
	var label:=Label3D.new();label.text="%s  •  100" % title
	var card:=Labels._measure_card(label,{},false,"",false,T.voice_font(),Rect2(0,0,1600,900),{},id)
	label.free()
	return card


func test_a_second_town_shows_the_watch_that_fights_there()->void:
	# A quarter of the people live there: a quarter of the forty on defence.
	var fights:=int(Combat.town_watch(TOWN).troops)
	assert_int(fights).is_equal(10)
	var strong:=Model.strength(false,TOWN)
	assert_int(int(strong.defenders)).is_equal(fights)
	var facts:={"strength":strong}
	var row:=Model.row_for("garrison",facts)
	assert_int(int(row.number)).is_equal(fights)
	assert_str(String(row.value)).is_equal("10 on watch")
	assert_str(String(row.value)).not_contains("none of its own")
	# Plain words: who they are, and that the trained stay home.
	assert_str(String(row.meaning)).contains("Townsfolk who take up arms").contains("Seanstone").not_contains("levy at home guards")
	row["marks"]=[]
	assert_str(Model._tip(row,facts)).not_contains("levy at home guards")
	# The map badge is the same count, and the battle's.
	assert_int(Labels.home_guard(TOWN)).is_equal(fights)
	assert_int(int(_card(TOWN,"Valebridge").badge)).is_equal(fights)
	# The drawing puts the watch at the gate.
	var sketch:=Model.sketch_data({"id":TOWN,"population":100,"places":120,"broken":0.0,"food_reported":false,"food_days":-1.0,"material":0.0,"logistics":0.0,"water":{},"completed":[],"strength":strong},"")
	assert_float(float(sketch.fields.garrison.low)).is_equal(float(fights))


func test_a_town_with_no_one_on_watch_says_so()->void:
	GameState.population_allocations["Defense"]=0
	assert_dict(Combat.town_watch(TOWN)).is_empty()
	var row:=Model.row_for("garrison",{"strength":Model.strength(false,TOWN)})
	assert_int(int(row.number)).is_equal(0)
	assert_str(String(row.value)).is_equal("no one on watch")
	assert_int(Labels.home_guard(TOWN)).is_equal(0)
	assert_int(int(_card(TOWN,"Valebridge").badge)).is_equal(0)


func test_a_town_someone_else_holds_keeps_no_watch_of_ours()->void:
	SettlementModel.settlement_record(TOWN)["occupied_by"]="civ_03"
	assert_int(int(Model.strength(false,TOWN).defenders)).is_equal(0)
	assert_int(Combat.defenders(TOWN)).is_equal(0)
	assert_int(Labels.home_guard(TOWN)).is_equal(0)
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
	assert_int(Labels.home_guard(home)).is_equal(0)
	assert_int(int(_card(home,"SEANSTONE").badge)).is_equal(0)


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


func test_scouted_towns_are_said_to_be_counted_like_for_like()->void:
	var facts:={"strength":Model.strength(false,TOWN)}
	var row:=Model.row_for("garrison",facts)
	row["marks"]=[]
	assert_str(Model._tip(row,facts)).not_contains("Scouts count")
	row["marks"]=[{"name":"Flintwick","low":0.0,"high":2.0,"words":"about 1","seen":"a season ago"}]
	assert_str(Model._tip(row,facts)).contains("Scouts count only trained fighters")


func test_the_map_reads_every_guard_in_one_pass_and_again_only_on_change()->void:
	_levy(12)
	var home:=_home_id()
	var probe:Probe=auto_free(Probe.new())
	var guards:Dictionary=probe._guards()
	assert_int(int(guards[home])).is_equal(Labels.home_guard(home))
	assert_int(int(guards[TOWN])).is_equal(Labels.home_guard(TOWN))
	assert_int(int(guards[TOWN])).is_equal(10)
	# Unchanged: the same reading, not a new one.
	assert_bool(is_same(probe._guards(),guards)).is_true()
	# The Defense share changes while the day stands still: read again.
	GameState.population_allocations["Defense"]=80
	assert_int(int(probe._guards()[TOWN])).is_equal(20)
	assert_int(int(probe._guards()[home])).is_equal(80)


func test_home_shows_its_levy_and_watch_as_its_battle_musters_them()->void:
	_levy(12)
	var home:=_home_id()
	# Home's battle: twelve trained and the rest of the forty on watch.
	var musters:=int(MilitaryCampaign._home_defense_force(false).troops)
	assert_int(musters).is_equal(40)
	assert_int(Combat.defenders(home)).is_equal(musters)
	var strong:=Model.strength(true,home)
	assert_int(int(strong.defenders)).is_equal(musters)
	var row:=Model.row_for("garrison",{"strength":strong})
	assert_int(int(row.number)).is_equal(musters)
	assert_str(String(row.value)).is_equal("40 fighters")
	assert_str(String(row.note)).is_equal("12 trained")
	# Home's badge appears, though its label carries no id of its own.
	assert_int(Labels.home_guard(home)).is_equal(musters)
	assert_int(int(_card(home,"SEANSTONE").badge)).is_equal(musters)
	# With more trained than the Defense share, every one of them stands.
	_levy(55)
	assert_int(Labels.home_guard(home)).is_equal(55)
	assert_int(int(MilitaryCampaign._home_defense_force(false).troops)).is_equal(55)
	assert_str(String(Model.row_for("garrison",{"strength":Model.strength(true,home)}).value)).is_equal("55 fighters")


func test_an_open_card_fits_its_name_and_badge_and_draws_one_badge()->void:
	var card:=_card(TOWN,"Valebridge")
	assert_int(int(card.badge)).is_greater(0)
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
