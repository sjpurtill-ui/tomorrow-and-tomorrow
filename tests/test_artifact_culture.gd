extends GdUnitTestSuite
## Artifact culture: study as a research role, three kinds of value, allure and
## its bounded effects, place-driven finds, sets, legends and rumors.
const E=preload("res://scripts/society_exchange.gd")
const A=preload("res://scripts/artifact_collection.gd")
const C=preload("res://scripts/artifact_culture.gd")
const S=preload("res://scripts/artifact_sites.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(777);DiscoverySystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(200);GameState.settlement_site_committed=true;GameState.housing_capacity=280
	GameState.population_allocations.Knowledge=30;GameState.population_allocations.Administration=12
	GameState.food_security=1;GameState.population_health=.95;GameState.water_metrics={"intake_ratio":1.0}
	GameState.simulation_metrics={"food_days":60,"food_intake_ratio":1.0,"security":.9,"cohesion":.9}
	GameState.resource_stockpiles.Food=20000;GameState.food_stocks={"Preserved food":20000.0}
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	CivilizationSystem.ground_survey_authority=Callable()
	WorldSimulation.create_actor("neighbor",777,Vector2(30,0));WorldSimulation.actors.neighbor.controller="manual"
	CivilizationSystem.civilizations.clear();CivilizationSystem.civilizations.append({"id":"neighbor","name":"Neighbor","world_position":Vector2(30,0),"strategic_regions":[],"player_relation":{"opinion":.3,"at_war":false,"contact_level":3}})
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	CivilizationSystem.ground_survey_authority=Callable()
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func held(point:Vector2=Vector2(100,100),rarity:int=-1)->Dictionary:
	var record:=A.find_at(777,point,1)
	if rarity>=0:record.rarity=rarity;record.work=20.0+rarity*20.0
	E.data().collections[record.id]=record
	return record

func rich_ground(point:Vector2)->Dictionary:
	# West of x=0 is a river valley; east is dry upland with no water.
	if point.x<0:return {"biome":"grassland","label":"River meadow","river_distance_km":1.0,"fertility":.8,"forage":.6,"game":.5}
	return {"biome":"desert","label":"Dry upland","river_distance_km":90.0,"fertility":.05}

# --- Research role --------------------------------------------------------------

func test_zero_allocation_never_studies_and_staffing_does()->void:
	var record:=held()
	C.set_study_weight(0)
	for day in range(1,40):GameState.elapsed_days=day;E.advance(day)
	assert_float(float(record.study)).is_equal(0.0)
	assert_str(String(C.artifact(record.id).state)).is_equal("unstudied")
	var before:=DiscoverySystem.research_emphasis_total()
	C.set_study_weight(3)
	assert_int(DiscoverySystem.research_emphasis_total()).is_equal(before+3)
	assert_float(float(A.study_capacity().researchers)).is_greater(0.0)
	for day in range(40,50):GameState.elapsed_days=day;E.advance(day)
	assert_float(float(record.study)).is_greater(0.0)
	for day in range(50,200):GameState.elapsed_days=day;E.advance(day)
	assert_float(float(record.study)).is_equal(1.0)
	assert_str(String(C.artifact(record.id).state)).is_equal("studied")

func test_study_role_draws_from_the_shared_research_budget()->void:
	var domain:=""
	for id:String in GameState.research_subcategory_allocations:
		for sub:String in GameState.research_subcategory_allocations[id]:
			if int(GameState.research_subcategory_allocations[id][sub])>0:domain=id+"|"+sub;break
		if domain!="":break
	var parts:=domain.split("|")
	var alone:=float(DiscoverySystem.research_capacity_for(parts[0],parts[1]).researchers)
	C.set_study_weight(4)
	assert_float(float(DiscoverySystem.research_capacity_for(parts[0],parts[1]).researchers)).is_less(alone)

func test_focus_piece_is_studied_first()->void:
	var first:=held(Vector2(100,100),0);var focus:=held(Vector2(900,100),2)
	assert_bool(C.set_study_focus(focus.id).has("ok")).is_true()
	C.set_study_weight(2)
	GameState.elapsed_days=2;E.advance(2)
	assert_float(float(focus.study)).is_greater(0.0)
	assert_float(float(first.study)).is_equal(0.0)

func test_ai_rulers_staff_the_role_when_holding_unstudied_pieces()->void:
	WorldSimulation.actors.neighbor.controller="ai"
	WorldSimulation.scoped("neighbor",func()->void:
		var record:=A.find_at(777,Vector2(500,500),1)
		WorldSimulation.state.society_exchange.collections[record.id]=record
		A.advance(1)
		assert_int(int(A.study_role().weight)).is_equal(1))

# --- Values -------------------------------------------------------------------

func test_studied_pieces_yield_culture_research_and_economic_value()->void:
	var record:=held(Vector2(100,100),2)
	var raw:=A.values(record)
	assert_float(float(raw.culture)+float(raw.research)+float(raw.economic)).is_equal(0.0)
	var culture_before:=A.bonus("culture")
	record.study=1.0;A.advance(1)
	var value:=A.values(record)
	assert_float(float(value.culture)).is_greater(0.0)
	assert_float(float(value.research)).is_greater(0.0)
	assert_float(float(value.economic)).is_greater(0.0)
	var summary:=C.summary()
	assert_int(int(summary.studied_count)).is_equal(1)
	assert_float(float(summary.value_totals.research)).is_greater(0.0)
	assert_float(A.bonus("culture")).is_greater(culture_before)
	assert_float(A.bonus(A.family_of(String(record.discovery_id)))).is_greater(float(A.summary().science)-.0001)
	assert_float(A.bonus(A.family_of(String(record.discovery_id)))).is_less(.5)
	var lean:=A.channels(record)
	assert_float(float(lean.culture)+float(lean.research)+float(lean.economic)).is_equal_approx(1.0,.0001)

func test_object_kind_changes_the_value_mix()->void:
	var flute:={"id":"a","name":"Bone flute","kind":"artifact","catalogue_id":10,"artifact_origin":"civilization","source_id":"x","discovery_id":"oral_epics","study":1.0}
	var rod:={"id":"b","name":"Measuring rod","kind":"artifact","catalogue_id":6,"artifact_origin":"civilization","source_id":"x","discovery_id":"standard_measures","study":1.0}
	assert_float(float(A.channels(flute).culture)).is_greater(float(A.channels(rod).culture))
	assert_float(float(A.channels(rod).research)).is_greater(float(A.channels(flute).research))

# --- Allure ---------------------------------------------------------------------

func test_allure_rises_with_studied_and_exhibited_prestige_and_is_bounded()->void:
	var base:=C.allure()
	for index in 6:held(Vector2(index*48,300),3).study=1.0
	var studied:=C.allure()
	assert_float(studied).is_greater(base)
	GameState.known_discoveries.append_array(["public_libraries","comparative_chronicles"])
	for item:Dictionary in E.data().collections.values():assert_bool(C.set_exhibited(item.id,true).has("ok")).is_true()
	assert_float(C.allure()).is_greater(studied)
	assert_float(C.allure()).is_less_equal(1.0)
	var report:=C.allure_report()
	assert_int(report.breakdown.size()).is_equal(4)
	assert_int(report.effects.size()).is_equal(3)
	assert_float(C.diplomatic_bonus({"openness":1.0})).is_less_equal(.14)
	assert_float(C.migration_bonus()).is_less_equal(.06)

func test_allure_changes_the_diplomatic_forecast_by_a_bounded_amount()->void:
	var before:Dictionary=WorldSimulation.diplomacy.forecast("neighbor","exchange","equals")
	assert_bool(before.has("score")).is_true()
	for index in 12:held(Vector2(index*48,300),4).study=1.0
	var after:Dictionary=WorldSimulation.diplomacy.forecast("neighbor","exchange","equals")
	var delta:=float(after.score)-float(before.score)
	assert_float(delta).is_greater(0.0)
	assert_float(delta).is_less_equal(.14)

func test_unstudied_pieces_cannot_be_exhibited_through_the_facade()->void:
	var record:=held()
	GameState.known_discoveries.append_array(["public_libraries","comparative_chronicles"])
	assert_bool(C.set_exhibited(record.id,true).has("error")).is_true()
	record.study=1.0
	assert_bool(C.set_exhibited(record.id,true).has("ok")).is_true()
	assert_bool(C.artifact(record.id).exhibited).is_true()

# --- Facade -------------------------------------------------------------------------

func test_listing_filters_sorts_pages_and_describes()->void:
	for index in 30:held(Vector2(index*24,700))
	var studied:=held(Vector2(0,5000),3);studied.study=1.0
	var page:=C.artifacts({"page_size":10,"sort":"rarity"})
	assert_int(int(page.total)).is_equal(31)
	assert_int(int(page.pages)).is_equal(4)
	assert_int(page.items.size()).is_equal(10)
	assert_int(int(page.items[0].rarity_index)).is_equal(3)
	assert_int(int(C.artifacts({"status":"studied"}).total)).is_equal(1)
	var piece:Dictionary=C.artifact(studied.id)
	for key:String in ["id","name","object","style","motif","material","rarity","rarity_index","origin","found_day","held_days","prestige","appraisal","study_progress","state","value","research_subject","exhibited","can_exhibit","story","texture","site_name","set_name","set_progress"]:
		assert_bool(piece.has(key)).override_failure_message("missing "+key).is_true()
	var summary:=C.summary()
	assert_int(int(summary.collection_count)).is_equal(31)
	assert_str(String(summary.study_role.allocation_key)).is_equal("artifact_study")

func test_stories_are_deterministic_short_and_varied()->void:
	var seen:Dictionary={}
	for index in 200:
		var record:=A.find_at(777,Vector2(index*24,1200),1)
		var story:=C.story(record)
		assert_str(story).is_equal(C.story(record))
		assert_int(story.length()).is_greater(30)
		assert_int(story.count(". ")+1).is_less_equal(4)
		seen[story]=true
	assert_int(seen.size()).is_greater(150)
	var made:={"id":"neighbor:clay","name":"Clay storage jar · etched river","kind":"artifact","catalogue_id":12,"artifact_origin":"civilization","source_id":"neighbor","source_name":"Neighbor","discovery_id":"clay_shaping","rarity":1}
	assert_str(C.story(made)).contains("Neighbor")

# --- Distribution ----------------------------------------------------------------------

func test_finds_concentrate_in_rich_ground()->void:
	CivilizationSystem.ground_survey_authority=rich_ground
	var rich:=0;var barren:=0
	for index in 60:
		if not S.discover(CivilizationSystem,Vector2(-50000-index*120,3000),1).is_empty():rich+=1
		if not S.discover(CivilizationSystem,Vector2(50000+index*120,3000),1).is_empty():barren+=1
	assert_int(rich).is_greater(barren*2)
	assert_int(rich).is_greater(40)

func test_site_and_legend_placement_is_deterministic()->void:
	var first:=S.region_site(777,12,-4);S._sites.clear()
	assert_dict(S.region_site(777,12,-4)).is_equal(first)
	var sites:=0
	for rx in 40:
		if not S.region_site(777,rx,3).is_empty():sites+=1
	assert_int(sites).is_between(4,24)
	var legends:=S.legends(777)
	assert_int(legends.size()).is_equal(S.LEGEND_COUNT)
	assert_dict(S.legends(777)[0]).is_equal(legends[0])
	var names:Dictionary={}
	for legend:Dictionary in legends:names[legend.legend_name]=true
	assert_int(names.size()).is_equal(S.LEGEND_COUNT)

func test_site_sets_are_coherent_exclusive_and_bounded()->void:
	var site:={}
	var rx:=0
	while site.is_empty():site=S.region_site(777,rx,7);rx+=1
	var first:=S.discover(CivilizationSystem,site.position,1)
	assert_str(String(first.site_id)).is_equal(String(site.id))
	E.data()["artifact_sites"]={first.id:true};E.data().collections[first.id]=first
	var second:Dictionary=WorldSimulation.scoped("neighbor",func()->Dictionary:return S.discover(CivilizationSystem,site.position,1))
	assert_str(String(second.id)).is_not_equal(String(first.id))
	assert_str(String(second.site_id)).is_equal(String(site.id))
	assert_str(A.descriptor(second).style).is_equal(A.descriptor(first).style)
	assert_str(A.descriptor(second).motif).is_equal(A.descriptor(first).motif)
	assert_int(int(first.rarity)).is_greater_equal(1)
	var alone:=A.prestige(first)
	E.data().collections[second.id]=second
	A.advance(0)
	assert_float(A.prestige(first)).is_greater(alone)
	assert_float(A.set_factor(first)).is_less_equal(1.5)
	assert_str(String(C.artifact(first.id).set_progress)).is_equal("2 of %d" % int(site.set_size))
	for index in int(site.set_size):E.data().artifact_sites[S.piece_id(site,index)]=true
	assert_bool(S.exhausted(site)).is_true()

func test_legendary_is_placed_named_and_never_rolled_in_the_open()->void:
	var legend:Dictionary=S.legends(777)[0]
	var found:Array=[]
	for attempt in 3:
		var piece:=S.discover(CivilizationSystem,legend.position,1)
		E.data()["artifact_sites"]=E.data().get("artifact_sites",{});E.data().artifact_sites[piece.id]=true
		found.append(piece)
	assert_int(int(found[2].rarity)).is_equal(4)
	assert_str(String(found[2].name)).is_equal(String(legend.legend_name))
	assert_str(C.story(found[2])).is_equal(String(legend.story))
	for index in 400:
		var scattered:=S.discover(CivilizationSystem,Vector2(90000+index*72,-7000),1)
		if not scattered.is_empty():assert_int(int(scattered.rarity)).is_less(4)

func test_rumors_are_vague_learned_from_contact_and_lead_to_digs_on_home_ground()->void:
	S.hear_from_society("neighbor","Neighbor",Vector2(30,0),5)
	var rumors:=C.rumored_sites("player")
	assert_int(rumors.size()).is_equal(1)
	var rumor:Dictionary=rumors[0]
	for key:String in ["id","name","hint","confidence","known_since_day","found"]:assert_bool(rumor.has(key)).is_true()
	assert_bool(rumor.found).is_false()
	assert_str(String(rumor.hint)).not_contains("km")
	var site:=S.site_by_id(String(rumor.id))
	assert_str(String(rumor.hint)).not_contains(str(roundi(site.position.x)))
	# Revealed home ground: ordinary sampling finds nothing, a remembered site can be dug.
	CivilizationSystem.ground_survey_authority=rich_ground
	CivilizationSystem._add_revealed_area(site.position,200,"visited")
	var sample:={"mission_id":3,"personnel":6,"carried_collections":[]}
	E.sample_ground(CivilizationSystem,sample,site.position,6)
	assert_array(sample.carried_collections).is_empty()
	var dig:={"mission_id":4,"personnel":6,"carried_collections":[]}
	S.dig_rumored(CivilizationSystem,dig,site.position+Vector2(10,0),6)
	assert_int(dig.carried_collections.size()).is_equal(1)
	assert_str(String(dig.carried_collections[0].site_id)).is_equal(String(site.id))
	S.dig_rumored(CivilizationSystem,dig,site.position,6)
	assert_int(dig.carried_collections.size()).is_equal(1)
	assert_bool(C.rumored_sites("player")[0].found).is_true()

# --- Save compatibility --------------------------------------------------------------------

func test_role_and_rumors_roundtrip_and_legacy_state_loads()->void:
	var record:=held();C.set_study_weight(2);C.set_study_focus(record.id)
	S.hear_from_society("neighbor","Neighbor",Vector2(30,0),5)
	A.advance(1)
	var saved:Dictionary=bytes_to_var(var_to_bytes(SaveSystem._capture_reflected(GameState,[])))
	assert_bool(E.valid(saved.society_exchange)).is_true()
	GameState.society_exchange=E.empty_state()
	assert_int(C.study_weight()).is_equal(0)
	assert_int(C.rumored_sites().size()).is_equal(0)
	GameState.society_exchange=saved.society_exchange
	assert_int(C.study_weight()).is_equal(2)
	assert_str(String(C.summary().study_role.focus_id)).is_equal(record.id)
	assert_int(C.rumored_sites().size()).is_equal(1)
	var legacy:=E.empty_state();legacy.collections[record.id]=record.duplicate(true)
	assert_bool(E.valid(legacy)).is_true()
	var bad:=E.empty_state();bad["artifact_study"]={"weight":99,"focus":""}
	assert_bool(E.valid(bad)).is_false()
	bad=E.empty_state();bad["artifact_rumors"]={"site:1:2":{"day":1,"confidence":4,"source":"","hint":""}}
	assert_bool(E.valid(bad)).is_false()

func test_display_names_read_as_titles_and_keep_saved_names()->void:
	var record:=held(Vector2(100,100))
	record.name="An ember under ash · a broad contact";record.insight="Ash keeps a coal alive."
	record.form="an ember under ash · a broad contact"
	var shown:=C.artifact(record.id)
	assert_str(String(shown.name)).is_equal("An Ember Under Ash")
	assert_str(String(shown.name)).not_contains("·")
	assert_str(String(shown.object)).contains("a broad contact")
	assert_str(String(shown.catalogue_name)).is_equal("An ember under ash · a broad contact")
	assert_str(String(record.name)).is_equal("An ember under ash · a broad contact")
	var made:={"id":"m","name":"Clay storage jar · etched river","kind":"artifact","catalogue_id":12,"artifact_origin":"civilization","source_id":"neighbor","discovery_id":"clay_shaping"}
	assert_str(String(C.display_name(made).name)).is_equal("Clay Storage Jar of the Etched River")
	var generic:={"id":"g","name":"Irregular rough stone bowl · earth-darkened","kind":"artifact","catalogue_id":0,"artifact_origin":"prehistoric","source_id":"","form":"rough stone bowl","discovery_id":"stone_sorting"}
	assert_str(String(C.display_name(generic).name)).is_equal("The Earth-Darkened Rough Stone Bowl")
	assert_int(C.artifacts({"search":"ember under ash"}).total).is_equal(1)

func test_sets_summarize_held_and_missing_pieces()->void:
	var site:={};var rx:=0
	while site.is_empty():site=S.region_site(777,rx,11);rx+=1
	for index in 2:
		var piece:=S.piece(site,index,1);E.data().collections[piece.id]=piece
	held(Vector2(4000,4000))
	var sets:=C.sets()
	assert_int(sets.size()).is_equal(1)
	assert_int(int(sets[0].held)).is_equal(2)
	assert_int(int(sets[0].total)).is_equal(int(site.set_size))
	assert_int(int(sets[0].missing)).is_equal(int(site.set_size)-2)
	assert_int(sets[0].items.size()).is_equal(2)
	assert_str(String(sets[0].site_name)).is_equal(String(site.name))

