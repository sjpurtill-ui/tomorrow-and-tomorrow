extends GdUnitTestSuite
## The Buildings page's City tab (dock_content_construction.gd _city_tab).
## The player: "Screen is boring and inconsequential and WEIRD, like why are
## there so many places when there are not that many people???" The tab leads
## with what the builders are doing and what holds them up, says where every
## place to sleep is (the tents carried on the journey or built here) and when
## more homes go up, and gives every figure a plain meaning. One ledger: each
## number is the engine's own, and recording the carried places adds or
## removes no place.

const Provider:=preload("res://scripts/hud/content/dock_content_construction.gd")
const Construction:=preload("res://scripts/settlement_construction.gd")
const Shelter:=preload("res://scripts/hud/shelter_status.gd")
const Blocks:=preload("res://scripts/hud/dock_blocks.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

class FakeHud extends Control:
	signal section_requested(section:String,sub:int)
	var opened:Array=[]
	func _init()->void:section_requested.connect(func(section:String,sub:int)->void:opened.append([section,sub]))
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider:Object,_sub:int=0)->void:pass

class StubTerrain extends Node:
	func _report_military_action(_r:Dictionary)->void:pass
	func _on_settlement_action_pressed()->void:pass

var hud:FakeHud
var terrain:StubTerrain
var _processing:Dictionary={}

func before()->void:
	for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]:_processing[node]=node.is_processing()

func after()->void:
	T.set_color_mode("light")
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	WorldSimulation.clear()
	for node:Node in _processing:node.set_process(bool(_processing[node]))

func before_test()->void:
	T.set_color_mode("light")
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(515151)
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	hud=FakeHud.new();add_child(hud)
	terrain=StubTerrain.new();add_child(terrain)

func after_test()->void:
	if is_instance_valid(hud):hud.queue_free()
	if is_instance_valid(terrain):terrain.queue_free()

# --------------------------------------------------------------------------
# Fixtures
# --------------------------------------------------------------------------

## A town settled `day` days ago with its founders' manifest (thirty carried
## shelters and their stores), `people` people and eight builders.
func _found(people:int,completed:Array,places:int,day:int=40)->void:
	ResourceSystem.initialize()
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.settlement_name="Seanstone";GameState.settlement_founded_day=0;GameState.elapsed_days=day
	GameState.settlement_completed.assign(completed)
	GameState.ensure_population_total(people)
	GameState.population_allocations={"Food":30,"Survey":6,"Extraction":8,"Construction":8,"Crafting":3,"Logistics":6,"Knowledge":4,"Administration":3,"Defense":3}
	GameState.simulation_metrics.merge({"labor_efficiency":0.72,"food_days":30.0,"logistics":0.2},true)
	GameState.water_metrics={"source_accessible":true,"intake_ratio":1.0}
	GameState.housing_capacity=places
	SettlementModel.ensure_founded()
	GameState.city_form={"tier":1.0,"condition":1.0,"materials_paid":1.0}
	SettlementModel.rebuild_summary()
	var room:=0.0
	for amount in ResourceSystem.storage_capacities().values():room+=float(amount)
	GameState.material_metrics["storage_capacity"]=room

func _page()->Dictionary:
	return Provider.new(terrain,hud).tab(0)

## Every card (or row) of the page by name.
static func _rows(page:Dictionary)->Dictionary:
	var rows:={}
	for block:Dictionary in page.get("blocks",[]):
		if not String(block.get("type","")) in ["rows","town_works"]:continue
		for item:Dictionary in block.get("items",block.get("cards",[])):rows[String(item.name)]=item
	return rows

## The page as the player reads it, for the handoff and for review.
static func _print(label:String,page:Dictionary)->void:
	print("=== CITY TAB: %s ===" % label)
	print("[brief] %s: %s" % [page.brief.get("title",""),page.brief.get("why","")])
	for block:Dictionary in page.blocks:
		print("-- %s%s" % [String(block.get("heading","(actions)")),(" · "+String(block.note)) if block.has("note") else ""])
		for item:Dictionary in block.get("items",block.get("cards",[])):
			if item.has("label"):print("   [button] %s: %s" % [item.label,item.get("sub","")]);continue
			print("   %s | %s | %s" % [item.name,item.get("value",""),item.get("sub","")])
			if String(item.get("detail",""))!="":print("      %s" % item.detail)

# --------------------------------------------------------------------------
# Housing: where the places are, and when more go up
# --------------------------------------------------------------------------

func test_seanstone_room_is_explained_by_the_tents_carried()->void:
	# The player's town: 97 people, 240 places. 150 are the thirty tents the
	# founders carried (an older save: no record yet), 90 the Lean-to Shelters.
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	assert_bool(GameState.founding_manifest.has("shelter_places")).is_false()
	var page:=_page()
	_print("97 people, 240 places",page)
	var rows:=_rows(page)
	var housing:Dictionary=rows.Housing
	assert_str(String(housing.value)).is_equal("240 places")
	assert_str(String(housing.sub)).is_equal("Everyone has a roof, with room for 143 more")
	assert_str(String(housing.detail)).contains("150 are in the tents carried on the journey and 90 in shelters built here")
	assert_str(String(housing.detail)).contains("newcomers and people brought home")
	# When more homes go up comes from the builders' own rule.
	var homes:Dictionary=rows["New homes"]
	assert_str(String(homes.value)).is_equal("Not needed yet")
	assert_int(Construction.housing_trigger_people()).is_equal(192)
	assert_str(String(homes.sub)).is_equal("Builders start more once over 192 people live here")
	assert_str(String(homes.detail)).is_equal("Then 8 builders add about 24 places every %s." % Plain.span_text(Construction.HOUSING_BATCH_WORK/Construction.housing_work_per_day()))
	assert_bool(Construction.housing_under_way()).is_false()
	GameState.population_total=193
	assert_bool(Construction.housing_under_way()).is_true()

func test_a_new_town_sleeps_in_its_carried_tents_until_it_builds()->void:
	_found(120,["Hearth Circle"],150,12)
	var page:=_page()
	_print("freshly founded, 120 people",page)
	var rows:=_rows(page)
	assert_str(String(rows.Housing.detail)).contains("No homes built yet: all 150 are in the tents carried on the journey")
	assert_str(String(rows["New homes"].sub)).is_equal("The Lean-to Shelters come first: room for 90 more")
	# Settling records the carried places without touching the ledger.
	Construction.process_day()
	assert_int(int(GameState.founding_manifest.shelter_places)).is_equal(150)
	assert_int(GameState.housing_capacity).is_equal(150)
	# The Lean-to Shelters add built places; the carried ones stay counted.
	GameState.resource_stockpiles["Timber"]=40.0
	GameState.settlement_projects["Lean-to Shelters"]=100.0
	Construction.process_day()
	assert_array(GameState.settlement_completed).contains(["Lean-to Shelters"])
	var h:=Construction.housing()
	assert_int(int(h.places)).is_equal(240)
	assert_int(int(h.carried)).is_equal(150)
	assert_int(int(h.built)).is_equal(Construction.lean_to_places())
	assert_str(String(Shelter.describe(GameState.settlement_completed,GameState.housing_capacity,97,int(h.carried)).detail)).contains("150 of them in the tents carried on the journey")

func test_old_saves_fall_back_to_the_founding_stock()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	assert_int(Construction.carried_places()).is_equal(150)
	# A founding that carried more shelter carried more places.
	GameState.founding_focus="generations"
	assert_int(Construction.carried_places()).is_equal(171)
	GameState.founding_focus=""
	var before:=GameState.housing_capacity
	Construction.record_carried_places()
	assert_int(int(GameState.founding_manifest.shelter_places)).is_equal(150)
	assert_int(GameState.housing_capacity).is_equal(before)
	# A later town's founders brought four places to each shelter they carried.
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(9,4),"primary":false,"population_share":0.2,"founded_day":0})
	var carried:int=SettlementModel.with_city_resources("second",func()->int:
		GameState.settlement_completed.assign(["Hearth Circle","Lean-to Shelters"])
		GameState.housing_capacity=int(GameState.housing_capacity)+90
		return Construction.carried_places())
	var shelters:=int(SettlementModel.settlement_record("second").local_resources.founding_manifest.portable_shelters)
	assert_int(carried).is_equal(4*shelters)

func test_a_second_town_shows_its_own_homes_and_work()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var home:Vector2=SettlementModel.settlement_record(GameState.selected_player_settlement_id).get("position",Vector2.ZERO)
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":home+Vector2(9,4),"primary":false,"population_share":0.2,"founded_day":20})
	assert_bool(bool(SettlementModel.select_settlement("second").ok)).is_true()
	var page:=_page()
	_print("a second town, just founded",page)
	assert_str(String((page.blocks[0] as Dictionary).heading)).is_equal("Rivermeet")
	var places:int=SettlementModel.with_city_resources("second",func()->int:return int(GameState.housing_capacity))
	var housing:Dictionary=_rows(page).Housing
	assert_str(String(housing.value)).is_equal("%d places" % places)
	assert_str(String(housing.detail)).contains("No homes built yet: all %d are in the tents carried on the journey" % places)
	# Its stores hold no timber yet: the builders wait, and say on what.
	assert_str(String(page.brief.title)).is_equal("The builders are waiting")

func test_tents_lost_to_fire_stay_lost_and_rebuilt_places_are_built()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	GameState.founding_manifest["shelter_places"]=150
	GameState.housing_capacity=120
	Construction.process_day()
	assert_int(int(GameState.founding_manifest.shelter_places)).is_equal(120)
	GameState.housing_capacity=200
	var h:=Construction.housing()
	assert_int(int(h.carried)).is_equal(120)
	assert_int(int(h.built)).is_equal(80)
	assert_int(int(h.places)).is_equal(int(h.carried)+int(h.built))

func test_shortage_says_who_sleeps_out_and_what_it_costs()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],80)
	var housing:Dictionary=_rows(_page()).Housing
	assert_str(String(housing.sub)).is_equal("17 of the 97 people sleep in the open")
	assert_str(String(housing.detail)).contains("sicker and slower at work")
	# 97 is over 64: the builders are putting up homes now.
	var homes:Dictionary=_rows(_page())["New homes"]
	assert_str(String(homes.sub)).starts_with("24 more places going up")

# --------------------------------------------------------------------------
# The builders: what they do now, how long, what holds them up
# --------------------------------------------------------------------------

func test_the_tab_leads_with_the_work_in_hand_at_the_engines_pace()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var current:=Construction._current_settlement_project()
	assert_dict(current).is_not_empty()
	var page:=_page()
	assert_str(String(page.brief.title)).is_equal("Building the %s" % current.name)
	var rate:=Construction.daily_work()
	var left:=(float(current.days)-float(GameState.settlement_projects.get(current.name,0.0)))/rate
	assert_str(String(page.brief.why)).contains("about %s left at today's pace" % Plain.span_text(left))
	var row:Dictionary=_rows(page)[String(current.name)]
	assert_str(String(row.detail)).contains(String(current.effect))
	assert_str(String(row.sub)).is_equal("About %s left at today's pace" % Plain.span_text(left))
	# Its bar is the work done, and its words the same days left.
	assert_float(float(row.progress.ratio)).is_equal_approx(float(GameState.settlement_projects.get(current.name,0.0))/float(current.days),0.000001)
	assert_str(String(row.progress.text)).is_equal("about %s left" % Plain.span_text(left))
	# The pace shown is the pace worked: a day adds exactly daily_work().
	var worked:=float(GameState.settlement_projects.get(current.name,0.0))
	Construction.process_day()
	assert_float(float(GameState.settlement_projects[current.name])-worked).is_equal_approx(rate,0.000001)

func test_waiting_builders_say_what_holds_them_up()->void:
	_found(120,["Hearth Circle"],150,12)
	GameState.resource_stockpiles["Timber"]=0.0;GameState.resource_stockpiles["Fiber Plants"]=0.0
	var page:=_page()
	_print("waiting on materials",page)
	assert_str(String(page.brief.title)).is_equal("The builders are waiting")
	assert_str(String(page.brief.why)).starts_with("Next is the Lean-to Shelters, which needs 25 more timber.")
	var row:Dictionary=_rows(page)["Lean-to Shelters"]
	assert_str(String(row.value)).is_equal("Waiting")
	assert_str(String(row.sub)).is_equal("Needs 25 more timber")
	assert_str(String(row.detail)).contains("adds room for 90 people")

func test_builders_row_counts_who_builds_and_the_actions_open_the_owning_pages()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var page:=_page()
	var builders:Dictionary=_rows(page).Builders
	assert_str(String(builders.value)).is_equal("8")
	assert_str(String(builders.sub)).is_equal("All on the town's works")
	var actions:Array=(page.blocks.back() as Dictionary).items
	for action:Dictionary in actions:(action.on_press as Callable).call()
	assert_array(hud.opened).contains_exactly([["construction",1],["overview",0]])
	GameState.population_allocations.Construction=0
	var idle:=_page()
	assert_str(String(idle.brief.title)).is_equal("No one is building")
	assert_str(String(_rows(idle).Builders.sub)).starts_with("No one is building")

# --------------------------------------------------------------------------
# Repair, era and workshops: each figure with its meaning
# --------------------------------------------------------------------------

func test_condition_says_how_it_moves_and_what_it_costs()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var condition:Dictionary=_rows(_page()).Condition
	assert_str(String(condition.value)).is_equal("100%")
	assert_str(String(condition.sub)).is_equal("Sound: the builders mend faster than it wears")
	assert_str(String(condition.detail)).contains("Makers work only as fast as their workshops are kept")
	# Too few builders and too little stone: it wears, and says by how much.
	GameState.city_form={"tier":1.0,"condition":0.7,"materials_paid":1.0}
	GameState.population_allocations.Construction=1
	var facts:=preload("res://scripts/upkeep_warnings.gd").facts()
	condition=_rows(_page()).Condition
	assert_str(String(condition.value)).is_equal("70%")
	assert_str(String(condition.sub)).is_equal("Wearing out: down %s%% a month" % Plain.number(-float(facts.monthly_change)*100.0))
	assert_str(String(condition.detail)).starts_with("%d builders would hold it." % int(facts.builders_to_hold))

func test_era_says_what_the_next_era_still_needs()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var era:Dictionary=_rows(_page())["Building era"]
	assert_str(String(era.value)).is_equal("Foothold")
	# Hamlet needs adopted framing, finished works and makers.
	assert_str(String(era.detail)).contains("adoption of")
	assert_bool(String(era.detail).contains("old (")).is_false()
	assert_str(String(era.detail)).contains("3 finished works (2 now)")
	assert_str(String(era.detail)).contains("4 makers (3 now)")
	GameState.elapsed_days=1;GameState.population_allocations.Crafting=5
	GameState.known_discoveries.append("framed_construction")
	GameState.discovery_adoption["framed_construction"]=0.2
	GameState.settlement_completed.append("Storage Pits")
	assert_str(String(_rows(_page())["Building era"].sub)).is_equal("Rising toward Hamlet")

func test_workshops_and_stores_name_the_hands_they_need()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var row:Dictionary=_rows(_page())["Workshops and stores"]
	assert_str(String(row.value)).is_equal("Short-handed")
	assert_str(String(row.sub)).is_equal("3 of 10 makers, 6 of 10 carriers")
	assert_float(float(row.needs[0].have)).is_equal(3.0);assert_float(float(row.needs[0].need)).is_equal(10.0)
	assert_str(String(row.detail)).contains("units of store room")

func test_every_row_is_plain_readable_and_has_a_meaning()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var page:=_page()
	var caps:=RegEx.create_from_string("\\b[A-Z]{3,}\\b")
	for text:String in [String(page.brief.title),String(page.brief.why)]:
		assert_object(caps.search(text)).override_failure_message(text).is_null()
	var count:=0
	for block:Dictionary in page.blocks:
		assert_object(caps.search(String(block.get("heading","")))).is_null()
		if not String(block.type) in ["rows","town_works"]:continue
		for item:Dictionary in block.get("items",block.get("cards",[])):
			count+=1
			assert_str(String(item.value)).override_failure_message(String(item.name)).is_not_empty()
			assert_str(String(item.sub)).override_failure_message(String(item.name)).is_not_empty()
			assert_str(String(item.get("detail",""))).override_failure_message(String(item.name)).is_not_empty()
			assert_bool(String(item.value).contains("·")).override_failure_message(String(item.value)).is_false()
			for text:String in [String(item.name),String(item.value),String(item.sub),String(item.get("detail",""))]:
				assert_object(caps.search(text)).override_failure_message(text).is_null()
	# The works, the defences, new homes and the town's five figures.
	assert_int(count).is_equal(8)
	# It draws: one ink row per item on the dock's paper.
	var body:=VBoxContainer.new();add_child(body)
	Blocks.render(body,page.blocks)
	assert_int(body.get_child_count()).is_equal(page.blocks.size())
	body.queue_free()

# --------------------------------------------------------------------------
# Changing the calendar alone cannot change the displayed milestone requirements.
# --------------------------------------------------------------------------

func test_era_support_and_missing_practices_do_not_depend_on_calendar()->void:
	_found(97,["Hearth Circle","Lean-to Shelters"],240)
	var before:Dictionary=_rows(_page())["Building era"]
	var supported:=SettlementModel._supported_fabric_tier(1)
	for years in [0,1,200,700,1500,10000]:
		GameState.elapsed_days=years*365.0
		assert_int(SettlementModel._supported_fabric_tier(int(GameState.elapsed_days))).is_equal(supported)
		assert_str(String(_rows(_page())["Building era"].detail)).is_equal(String(before.detail))
