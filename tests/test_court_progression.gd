extends GdUnitTestSuite
## Capability-reference progression: catches hand-picked, future-dated capture
## knowledge without claiming that a research simulation has reached this pace.

const Reference:=preload("res://tests/court_eval/progression_fixture.gd")
const Stages:=preload("res://scripts/civic_stages.gd")
const Presentation:=preload("res://scripts/hud/court_presentation.gd")
const Chapters:=preload("res://scripts/hud/court_chapters.gd")
const Stage:=preload("res://scripts/hud/court_stage.gd")
const Director:=preload("res://scripts/hud/court_director.gd")
const Voice:=preload("res://scripts/character_voice.gd")
var _timeline:Dictionary={}

func before()->void:
	DiscoverySystem.initialize()
	for year in range(0,3001,200):_timeline[year]=Reference.known_at(year)

func before_test()->void:
	Stages.stage_override="";Stages.reload();Voice.knowledge_override.clear()
	GameState.reset_for_new_world(76215)

func after_test()->void:
	Stages.stage_override="";Stages.reload();Voice.knowledge_override.clear()

func test_reference_uses_live_dates_and_completed_foundations_at_all_boundaries()->void:
	var previous:Array=[]
	for year in range(0,3001,200):
		var known:Array=_timeline[year]
		var held:Dictionary={}
		for id:String in known:held[id]=true
		for id:String in previous:assert_bool(held.has(id)).is_true()
		for id:String in known:
			assert_bool(DiscoverySystem.catalog_by_id.has(id)).is_true()
			if id in Reference.Founding.PRACTICES:continue
			var entry:Dictionary=DiscoverySystem.catalog_by_id[id]
			assert_float(Reference.year_of(entry)).override_failure_message("Future discovery at %s: %s" % [year,id]).is_less_equal(float(year))
			assert_bool(Reference.foundations_met(entry,held)).override_failure_message("Missing foundation at %s: %s" % [year,id]).is_true()
		previous=known
	assert_bool("fitted_tailoring" in _timeline[1400]).is_false()
	assert_bool("royal_chancery_office" in _timeline[1400]).is_false()
	assert_bool("fitted_tailoring" in _timeline[1800]).is_true()

func test_the_same_knowledge_drives_room_dress_and_civic_profile()->void:
	for year in range(0,3001,200):
		var known:Array=_timeline[year]
		GameState.elapsed_days=float(year)*365.0
		Voice.knowledge_override["player"]=known.duplicate()
		var stage:=Stages.current()
		var profile:=Presentation.for_owner()
		var chapter:=Chapters.for_owner()
		assert_str(String(profile.stage_id)).is_equal(String(stage.id))
		assert_str(String(profile.lean)).is_equal(String(chapter.lean))
		assert_int(int(chapter.index)).is_equal(year/200)
		assert_dict(profile).is_equal(Presentation.from_knowledge(known,stage))
		assert_dict(chapter).is_equal(Chapters.derive(year*365.0,known,stage))
		print("COURT_PROGRESSION year=%d known=%d civic=%s dress=%s greeting=%s room=%s" % [year,known.size(),stage.id,profile.outfit,profile.routine_greeting,chapter.set_kind])

func test_foreign_identity_keeps_its_dress_and_greeting_in_a_later_host_room()->void:
	GameState.elapsed_days=3000.0*365.0
	Voice.knowledge_override={"player":_timeline[3000].duplicate(),"visitor":_timeline[200].duplicate()}
	var host:=Presentation.for_owner()
	var visitor:=Presentation.for_owner("visitor")
	var facts:={"presentation":host,"presentations":{"player":host,"visitor":visitor}}
	var person:={"name":"Visiting envoy","person_id":198,"age":38,"sex":"female","appearance_civ_id":"visitor"}
	var member:=Director.cast_member(person,{"key":"main","role":"main"})
	assert_str(String(Stage.figure_look(person).outfit)).is_equal(String(visitor.outfit))
	assert_str(Director.routine_act(facts,member,"bow")).is_equal(String(visitor.routine_greeting))
	assert_str(String(Chapters.for_owner("visitor").set_kind)).is_not_equal(String(Chapters.for_owner().set_kind))
	assert_int(int(Chapters.for_owner("visitor").index)).is_equal(15)

func test_reference_and_profiles_do_not_grant_discoveries_or_change_the_government()->void:
	var known_before:Array=GameState.known_discoveries.duplicate()
	var form_before:=GovernmentPeopleSystem.government_form()
	var days_before:=GameState.elapsed_days
	var source:Array=_timeline[1800].duplicate()
	var original:=source.duplicate()
	Reference.snapshot(3000,source)
	assert_array(source).is_equal(original)
	assert_array(GameState.known_discoveries).is_equal(known_before)
	assert_str(GovernmentPeopleSystem.government_form()).is_equal(form_before)
	assert_float(GameState.elapsed_days).is_equal(days_before)

func test_reference_is_deterministic_and_keeps_missing_foundations_missing()->void:
	var excluded:=["warp_weighted_looms"]
	var original:=excluded.duplicate()
	var limited:=Reference.known_at(200,excluded)
	assert_bool("warp_weighted_looms" in limited).is_false()
	assert_bool("plain_weaving" in limited).is_false()
	assert_array(Reference.known_at(200,excluded)).is_equal(limited)
	assert_array(excluded).is_equal(original)
