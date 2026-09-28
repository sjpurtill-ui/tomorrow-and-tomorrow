extends GdUnitTestSuite
## "I've conquered this city. This screen makes no sense now!" A town we hold
## is reported by our own garrison: exact figures, no stale stamp, no ranges,
## no scouts, one row of things to do. Lose it and the scouts' view returns.

const CC:=preload("res://scripts/court_commands.gd")
const Held:=preload("res://scripts/held_town.gd")
const Dock:=preload("res://scripts/hud/content/dock_detail_foreign_city.gd")
const HeldDossier:=preload("res://scripts/hud/held_town_dossier.gd")
const Labels:=preload("res://scripts/hud/city_labels.gd")
const Ownership:=preload("res://scripts/map_ownership.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Director:=preload("res://scripts/audience_director.gd")

## Words that belong only to a scout's report.
const SCOUT_WORDS:=["stale","scouts","much may have changed","brought home by","gold mark","days ago","not yet seen","estimate"," est. "]

var city:=Vector2.ZERO
var city_id:=""
var civ_id:=""
var _processing:Dictionary={}

class FakeCourt extends Node:
	var opened:Array=[]
	func open_court(focus:Dictionary={})->Control:
		opened.append(focus.duplicate());return null

func _land(_p:Vector2)->bool:
	return true

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GameState.settlement_name="Seanstone"
	GameState.society_capacities["institutions"]=0.4
	GovernmentPeopleSystem._update_government_stage(false)
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ["name"]="Esurai"
	civ_id=String(civ.id)
	var relation:Dictionary=civ.player_relation
	relation.at_war=true; relation.contact_level=2; relation.home_location_known=true
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren"
	region["population"]=300.0
	city_id=String(region.id)
	# The scouts saw it two days before it fell: that old report must not show.
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",city_id,.6,int(GameState.elapsed_days)-2,"field campaign report","test"),int(GameState.elapsed_days)-2)
	city=CivilizationSystem.player_world_origin+Vector2(-20.0,8.0)
	CivilizationSystem.city_intelligence.records.player[city_id]["position"]={"x":city.x,"z":city.y}
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
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

## Tsaren taken; 17 of the band hold it, as in the user's game.
func _take_tsaren()->Dictionary:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+18
	MilitaryCampaign.raise_recruits(18)
	MilitaryCampaign.start_training("levy","improvised",18)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	MilitaryCampaign.create_field_army(18,"LEVY BAND 1")
	var army:Dictionary=MilitaryCampaign.field_armies[0]
	army["supply_level"]=1.0; army["readiness"]=1.0
	army["position"]={"x":city.x+0.3,"z":city.y}
	army["location_id"]=city_id; army["location_name"]="Tsaren"; army["status"]="stationed"
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	civ.strategic_regions[ri]["last_control_change_day"]=int(GameState.elapsed_days)
	var source:Dictionary=MilitaryCampaign.field_armies[0]
	var factor:=maxf(.05,float(source.get("supply_level",1.0))*(.5+.5*clampf(float(source.get("readiness",.45))*.9,.15,1.0)))
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],floorf(17.0*factor),int(army.army_id))
	assert_int(int(garrison.get("troops",0))).is_equal(17)
	return MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(int(army.army_id))]

## Every word a rendered control shows.
func _texts(node:Node)->String:
	var out:PackedStringArray=[]
	if node is Label:out.append((node as Label).text)
	if node is Button:out.append((node as Button).text)
	for child in node.get_children():out.append(_texts(child))
	return "\n".join(out)

func _render(held:Dictionary)->Control:
	var dossier:Control=auto_free(HeldDossier.new())
	add_child(dossier)
	dossier.setup({"report":held,"caption":"Ours · taken from the Esurai"})
	return dossier

func _assert_no_scout_words(text:String)->void:
	var lower:=text.to_lower()
	for word:String in SCOUT_WORDS:assert_str(lower).override_failure_message("'%s' in: %s" % [word,text]).not_contains(word)
	# No ranges: "70–110" style figures.
	var dash:=RegEx.new();dash.compile("\\d\\s*[–-]\\s*\\d")
	assert_object(dash.search(text)).override_failure_message(text).is_null()

func test_a_held_town_gets_our_garrisons_report_not_the_scouts()->void:
	_take_tsaren()
	var held:=Held.report(city_id)
	assert_dict(held).is_not_empty()
	assert_int(int(held.residents)).is_equal(300)
	assert_int(int(held.garrison)).is_equal(17)
	var dock:=Dock.new(null,null,city_id)
	assert_str(String(dock.meta().eyebrow)).is_equal("Our town")
	var blocks:Array=dock.tab(0).blocks
	var types:=blocks.map(func(b:Dictionary)->String:return String(b.get("type","")))
	assert_array(types).contains(["held_town","actions"])
	assert_array(types).not_contains(["city_dossier"])
	var text:=_texts(_render(held))
	_assert_no_scout_words(text)
	assert_str(text).contains("300 people live in Tsaren now")
	assert_str(text).contains("Seanstone has 900")
	assert_str(text).contains("17 of ours hold it")
	assert_str(text).contains("Nothing has been done to its people since we took it.")
	# The vignette carries no freshness stamp.
	var sketch:=HeldDossier.sketch_data(held,"")
	assert_str(String(sketch.fresh_status)).is_empty()

func test_what_was_done_there_is_told_with_exact_figures()->void:
	var band:=_take_tsaren()
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	var r:=CC.hear(String(audience.id),"Put the men of Tsaren to the sword")
	assert_str(String(r.war.verdict)).is_equal("fate")
	var killed:=int(r.objective.killed)
	assert_int(killed).is_greater(0)
	var held:=Held.report(city_id)
	assert_dict(held).is_not_empty()
	assert_int(int(held.residents)).is_equal(roundi(float(CivilizationSystem.region_snapshot(civ_id,city_id).population)))
	var text:=_texts(_render(held))
	_assert_no_scout_words(text)
	assert_str(text).contains("%d of its people were put to the sword." % killed)
	assert_str(text).contains("%d people live in Tsaren now" % int(held.residents))

func test_captives_on_the_road_are_counted_while_we_hold_the_town()->void:
	var band:=_take_tsaren()
	var audience:=Hall.summon({"figure_id":String((band.commander as Dictionary).get("figure_id",""))})
	var r:=CC.hear(String(audience.id),"Take the women and children of Tsaren home as captives and hold the town")
	var held:=Held.report(city_id)
	assert_int(int(r.get("objective",{}).get("captives",0))).override_failure_message(str(r.get("actor_says",""))).is_greater(0)
	assert_dict(held).is_not_empty()
	var text:=_texts(_render(held))
	assert_str(text).contains("captives are on the road to Seanstone")

func test_the_action_row_speaks_to_the_war_leader_about_the_town()->void:
	_take_tsaren()
	var court:=FakeCourt.new();court.add_to_group(Director.GROUP);add_child(court)
	var dock:=Dock.new(null,null,city_id)
	var actions:Array=[]
	for block:Dictionary in dock.tab(0).blocks:
		if String(block.type)=="actions":actions=block.items
	assert_int(actions.size()).is_equal(2)
	var held:=Held.report(city_id)
	var who:=String(held.general).get_slice(" ",0)
	assert_str(who).is_not_empty()
	assert_str(String(actions[0].label)).is_equal("Speak to %s about Tsaren" % who)
	assert_bool(bool(actions[0].primary)).is_true()
	assert_str(String(actions[1].label)).is_equal("Show on map")
	(actions[0].on_press as Callable).call()
	assert_int(court.opened.size()).is_equal(1)
	var focus:Dictionary=court.opened[0]
	assert_bool(focus.has("figure_id") or focus.has("person_id")).is_true()
	assert_str(String(focus.get("matter",""))).contains("Tsaren")
	court.queue_free()

func test_a_town_we_lose_again_returns_to_the_scouts_view_with_its_holder()->void:
	_take_tsaren()
	assert_bool(Held.held(city_id)).is_true()
	# The Esurai take it back; our garrison is gone.
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.strategic_regions[CivilizationSystem._region_index(civ,city_id)]["controller"]=civ_id
	MilitaryCampaign.occupation_forces.clear()
	assert_dict(Held.report(city_id)).is_empty()
	var dock:=Dock.new(null,null,city_id)
	assert_str(String(dock.meta().eyebrow)).is_equal("City report")
	var types:=(dock.tab(0).blocks as Array).map(func(b:Dictionary)->String:return String(b.get("type","")))
	assert_array(types).contains(["city_dossier"])
	assert_array(types).not_contains(["held_town"])
	var known:=CivilizationSystem.city_intelligence.known("player",city_id)
	assert_str(String(known.controller)).is_equal(civ_id)
	assert_str(String(Ownership.status(known).kind)).is_not_equal("occupied")

func test_the_map_card_agrees_with_the_report()->void:
	_take_tsaren()
	var known:=CivilizationSystem.city_intelligence.known("player",city_id)
	var ownership:=Ownership.status(known)
	var label:=Label3D.new();label.text="Tsaren  •  est. 70–110";label.set_meta("city_map_id",city_id)
	var card:=Labels._measure_card(label,CivilizationSystem.city_intelligence.records.player[city_id],true,String(ownership.line),false,preload("res://scripts/hud/hud_tokens.gd").voice_font(),Rect2(0,0,1600,900),ownership)
	label.free()
	assert_bool(bool(card.summary.get("held",false))).is_true()
	assert_str(String(card.count)).is_equal("Population 300")
	assert_str(String(card.status).to_lower()).not_contains("stale")
	var values:=(card.summary.stats as Array).map(func(s:Dictionary)->String:return String(s.value))
	assert_array(values).contains(["300","17"])
