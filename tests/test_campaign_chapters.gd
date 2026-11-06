extends GdUnitTestSuite
const Chapters:=preload("res://scripts/campaign_chapters.gd")
const Paths:=preload("res://scripts/knowledge_pathways.gd")
const Save:=preload("res://scripts/save_system.gd")

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	MilitaryCampaign.reset_for_new_world()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()

func after_test()->void:WorldSimulation.clear()

func _strong()->Dictionary:
	return {"trained":20.0,"military_need":8.0,"soldiers":20.0,"goods":100.0,"goods_need":50.0,"makers":5.0,"administrators":10.0,"administration_need":3.0,"legitimacy":0.8,"cohesion":0.8,"food_security":0.9}

func test_ten_chapters_have_real_distinct_milestones_and_actual_branching()->void:
	assert_int(Chapters.definitions().size()).is_equal(10)
	for chapter:Dictionary in Chapters.definitions():
		assert_int(int(chapter.end)-int(chapter.start)).is_equal(300)
		assert_int(chapter.routes.size()).is_equal(3)
		for route:Dictionary in chapter.routes:
			assert_int(route.milestones.size()).is_equal(2)
			for id:String in route.milestones:
				var entry:=DiscoverySystem.discovery_definition(id)
				assert_bool(entry.is_empty()).override_failure_message(id).is_false()
				assert_int(Chapters.chapter_of(entry)).override_failure_message(id).is_equal(int(chapter.id))
				assert_int(Paths.definition_parents(entry).size()).is_greater(0)

func test_every_route_can_advance_without_the_other_routes_or_calendar_wait()->void:
	for chapter:Dictionary in Chapters.definitions():
		for route:Dictionary in chapter.routes:
			DiscoverySystem.chapter_progress=Chapters.fresh();DiscoverySystem.chapter_progress.index=int(chapter.id)
			var known:Array=route.milestones.duplicate()
			for day in range(1,90):assert_dict(Chapters.advance(DiscoverySystem,day,1,_strong(),known)).is_empty()
			var result:=Chapters.advance(DiscoverySystem,90,1,_strong(),known)
			assert_str(String(result.get("route",""))).is_equal(String(route.name))
			assert_int(Chapters.index(DiscoverySystem)).is_equal(mini(9,int(chapter.id)+1))
			assert_bool(bool(DiscoverySystem.chapter_progress.completed)).is_equal(int(chapter.id)==9)

func test_shortfall_resets_sustained_progress_and_duplicate_reads_do_nothing()->void:
	var known:Array=Chapters.definitions()[0].routes[0].milestones.duplicate()
	for day in range(1,50):Chapters.advance(DiscoverySystem,day,1,_strong(),known)
	var c:=_strong();c.trained=0.0
	Chapters.advance(DiscoverySystem,50,1,c,known)
	assert_int(int(DiscoverySystem.chapter_progress.streaks.military)).is_equal(0)
	Chapters.advance(DiscoverySystem,51,1,_strong(),known)
	Chapters.advance(DiscoverySystem,51,1,_strong(),known)
	assert_int(int(DiscoverySystem.chapter_progress.streaks.military)).is_equal(1)
	Chapters.advance(DiscoverySystem,9000,1,_strong(),known)
	assert_int(int(DiscoverySystem.chapter_progress.streaks.military)).is_equal(1)

func test_knowledge_alone_or_calendar_alone_never_earns_a_chapter()->void:
	var c:=_strong();c.trained=0;c.goods=0;c.administrators=0
	var known:Array=[]
	for route:Dictionary in Chapters.definitions()[0].routes:known.append_array(route.milestones)
	for day in range(1,200):Chapters.advance(DiscoverySystem,day,1,c,known)
	assert_int(Chapters.index(DiscoverySystem)).is_equal(0)
	Chapters.advance(DiscoverySystem,1000000,1000000,_strong(),[])
	assert_int(Chapters.index(DiscoverySystem)).is_equal(0)

func test_chapter_frontier_removes_date_drag_but_keeps_prerequisite_and_material_rules()->void:
	var early:=DiscoverySystem.discovery_definition("shield_wall")
	assert_float(DiscoverySystem.research_early_factor(early)).is_equal(1.0)
	var next:=DiscoverySystem.discovery_definition("bronze_weaponry")
	assert_float(DiscoverySystem.research_early_factor(next)).is_greater(1.0)
	DiscoverySystem.chapter_progress.index=1
	assert_float(DiscoverySystem.research_early_factor(next)).is_equal(1.0)
	assert_bool(DiscoverySystem._discovery_is_eligible(next,0)).is_false()
	assert_float(DiscoverySystem.learning_year()).is_equal(0.0)

func test_reflected_save_keeps_chapter_streak_history_and_focus()->void:
	DiscoverySystem.chapter_progress={"index":3,"last_day":900,"streaks":{"civic":48},"history":[{"chapter":2,"route":"Civic strength"}],"completed":false,"focus":"civic"}
	var snapshot:=Save._capture_reflected(DiscoverySystem,[])
	DiscoverySystem.chapter_progress=Chapters.fresh()
	Save._apply_reflected(DiscoverySystem,snapshot,[])
	assert_int(Chapters.index(DiscoverySystem)).is_equal(3)
	assert_int(int(DiscoverySystem.chapter_progress.streaks.civic)).is_equal(48)
	assert_str(String(DiscoverySystem.chapter_progress.focus)).is_equal("civic")
	assert_int(DiscoverySystem.chapter_progress.history.size()).is_equal(1)

func test_equal_actor_inputs_advance_equally_and_other_actor_stays_behind()->void:
	WorldSimulation.create_actor("chapter_a",4242);WorldSimulation.create_actor("chapter_b",4242)
	var known:Array=Chapters.definitions()[0].routes[0].milestones.duplicate()
	for id:String in ["chapter_a","chapter_b"]:
		WorldSimulation.scoped(id,func()->void:
			for day in range(1,91):Chapters.advance(WorldSimulation.discovery,day,1,_strong(),known)
			assert_int(Chapters.index(WorldSimulation.discovery)).is_equal(1)
			assert_float(WorldSimulation.discovery.research_early_factor(WorldSimulation.discovery.discovery_definition("bronze_weaponry"))).is_equal(1.0)
		)
	assert_int(Chapters.index(DiscoverySystem)).is_equal(0)
	assert_int(DiscoverySystem.chapter_progress.history.size()).is_equal(0)

func test_unarmed_untrained_or_unfit_forces_do_not_count_as_military_capability()->void:
	MilitaryCampaign.home_army={"formations":[{"count":20,"training":0.4,"personnel_condition":1.0,"equipment":0,"equipment_required":20}]}
	assert_float(float(Chapters.capabilities().trained)).is_equal(0.0)
	MilitaryCampaign.home_army.formations[0].equipment=20
	assert_float(float(Chapters.capabilities().trained)).is_equal(20.0)
	MilitaryCampaign.home_army.formations[0].training=0.1
	assert_float(float(Chapters.capabilities().trained)).is_equal(0.0)

func test_manual_focus_preserves_finite_workforce_and_existing_question_progress()->void:
	var allocation:=GameState.population_allocations.duplicate(true)
	GameState.discovery_progress["tallies"]=0.43
	Chapters.focus(DiscoverySystem,"military")
	assert_dict(GameState.population_allocations).is_equal(allocation)
	assert_float(float(GameState.discovery_progress.tallies)).is_equal(0.43)
	assert_bool(Chapters.focus_ids(DiscoverySystem).has("shield_wall")).is_true()
	assert_bool(Chapters.focus_ids(DiscoverySystem).has("temple_high_steward")).is_false()
	Chapters.focus(DiscoverySystem,"")
	assert_bool(Chapters.focus_ids(DiscoverySystem).has("temple_high_steward")).is_true()

func test_legacy_campaign_enters_from_real_knowledge_without_fabricating_results()->void:
	GameState.known_discoveries.append("black_powder")
	Save._apply_reflected(DiscoverySystem,{"learning_lead":4.0},[])
	assert_int(Chapters.index(DiscoverySystem)).is_equal(5)
	assert_int(int(DiscoverySystem.chapter_progress.legacy_entry)).is_equal(5)
	assert_array(DiscoverySystem.chapter_progress.history).is_empty()
	assert_bool(GameState.known_discoveries.has("black_powder")).is_true()

func test_first_qualifying_batched_day_cannot_claim_the_previous_month()->void:
	var known:Array=Chapters.definitions()[0].routes[0].milestones.duplicate()
	Chapters.advance(DiscoverySystem,30,30,_strong(),known)
	assert_int(int(DiscoverySystem.chapter_progress.streaks.military)).is_equal(1)
	Chapters.advance(DiscoverySystem,60,30,_strong(),known)
	assert_int(int(DiscoverySystem.chapter_progress.streaks.military)).is_equal(31)

func test_explicit_route_focus_changes_the_real_scheduler_without_discounting_work()->void:
	var route:={"id":"shield_wall","name":"Route milestone","dynamic":"security","subcategory":"Organized defense","earliest_year":0.0,"requires":[],"requires_all":[],"requires_any":[],"signals":[],"chance":0.001}
	var other:={"id":"chapter_unrelated","name":"Unrelated quick question","dynamic":"security","subcategory":"Organized defense","earliest_year":0.0,"requires":[],"signals":[],"chance":0.1}
	DiscoverySystem.technology_catalog.assign([route,other])
	DiscoverySystem._scan.clear_catalog();DiscoverySystem._scan.clear_batch();DiscoverySystem._work_memo.clear()
	DiscoverySystem.catalog_by_channel={"security::Organized defense":[route,other]}
	DiscoverySystem.catalog_by_id["shield_wall"]=route;DiscoverySystem.catalog_by_id["chapter_unrelated"]=other
	GameState.research_subcategory_allocations={"security":{"Organized defense":1}}
	GameState.active_investigations.clear();GameState.research_targets.clear()
	var day:=int(GameState.elapsed_days)
	DiscoverySystem.chapter_progress.focus="";DiscoverySystem.chapter_cache=Chapters.Cache.new()
	assert_str(String(DiscoverySystem._quickest_in_line("security",day,{}).id)).is_equal("chapter_unrelated")
	var work:=DiscoverySystem._work_today(route,day)
	DiscoverySystem.chapter_progress.focus="military";DiscoverySystem.chapter_cache=Chapters.Cache.new()
	assert_str(String(DiscoverySystem._quickest_in_line("security",day,{}).id)).is_equal("shield_wall")
	assert_float(DiscoverySystem._work_today(route,day)).is_equal(work)
