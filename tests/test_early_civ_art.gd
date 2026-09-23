extends GdUnitTestSuite
const Art:=preload("res://scripts/hud/early_civ_art.gd")
const Person:=preload("res://scripts/hud/person_portrait.gd")
func test_owner_and_identity_survive_role_change_and_json()->void:
	var person:={"person_id":17,"appearance_civ_id":"rival_7","appearance_world_seed":82,"title":"Builder"}
	var copy:Dictionary=JSON.parse_string(JSON.stringify(person));copy.title="Steward"
	assert_int(Art.profile(copy)).is_equal(Art.profile(person))
	assert_int(Person.index_for(copy)).is_equal(Person.index_for(person))
	var before:=Art.person_scene(person,Person.index_for(person)) as AtlasTexture
	var after:=Art.person_scene(copy,Person.index_for(copy)) as AtlasTexture
	assert_object(before.atlas).is_same(after.atlas)
	assert_vector(before.region.position).is_equal(after.region.position)
func test_civic_practice_depends_on_values_not_ancestry()->void:
	assert_int(Art.civic_index({"hierarchy":.8,"centralization":.8})).is_equal(0)
	assert_int(Art.civic_index({"hierarchy":.2,"pluralism":.8})).is_equal(1)
	assert_int(Art.civic_index({"common_stewardship":.8})).is_equal(2)
	assert_int(Art.civic_index({})).is_equal(3)
	var person:={"person_id":7,"appearance_civ_id":"rival_2","appearance_world_seed":81}
	var before:=Art.profile(person);person["hierarchy"]=1.0;person["personality"]={"anger":1.0}
	assert_int(Art.profile(person)).is_equal(before)
func test_all_scene_crops_stay_within_source_and_keep_aspect()->void:
	for family in range(Art.PATHS.size()):
		var cols:=5 if family==3 else 2
		var rows:=1 if family==3 else 2
		for index in range(cols*rows):
			var image:=Art.cell(Art.PATHS[family],index,cols,rows)
			assert_bool(image.region.position.x>=0 and image.region.position.y>=0).is_true()
			assert_bool(image.region.end.x<=image.atlas.get_width() and image.region.end.y<=image.atlas.get_height()).is_true()
			assert_float(image.region.size.x/image.region.size.y).is_equal_approx(float(image.atlas.get_width())/cols/(float(image.atlas.get_height())/rows),.001)
func test_character_widget_contains_action_instead_of_stretching()->void:
	var saved:=GameState.elapsed_days;GameState.elapsed_days=365
	var image:=Person.picture({"person_id":3,"name":"Known steward"},150,150)
	assert_int(image.stretch_mode).is_equal(TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert_int(int(image.get_meta("person_id"))).is_equal(3)
	image.free();GameState.elapsed_days=saved

func test_saved_cast_assignment_prioritizes_cabinet_and_survives_role_change()->void:
	var saved_people:=GovernmentPeopleSystem.people
	var saved_stage:=GovernmentPeopleSystem.government_stage;GovernmentPeopleSystem.government_stage=3
	var saved_positions:Dictionary=WorldSimulation.state.leadership_positions.duplicate(true)
	GovernmentPeopleSystem.people=[]
	for id in range(1,9):GovernmentPeopleSystem.people.append({"person_id":id})
	WorldSimulation.state.leadership_positions={"Steward":{"person_id":5},"Quartermaster":{"person_id":6},"Marshal":{"person_id":7},"Scholar":{"person_id":8}}
	GovernmentPeopleSystem._assign_early_art_indices()
	var seen:Dictionary={}
	for office in GovernmentPeopleSystem.active_offices():
		var holder:Dictionary=WorldSimulation.state.leadership_positions.get(String(office.key),{})
		if holder.is_empty():continue
		var record:=GovernmentPeopleSystem._person_record(int(holder.person_id))
		assert_bool(seen.has(int(record.early_art_index))).is_false()
		seen[int(record.early_art_index)]=true
	var before:=JSON.stringify(GovernmentPeopleSystem.people)
	WorldSimulation.state.leadership_positions={}
	GovernmentPeopleSystem._assign_early_art_indices()
	assert_str(JSON.stringify(GovernmentPeopleSystem.people)).is_equal(before)
	GovernmentPeopleSystem.people=saved_people
	GovernmentPeopleSystem.government_stage=saved_stage
	WorldSimulation.state.leadership_positions=saved_positions

func test_early_unit_art_is_specific_and_later_units_keep_their_assets()->void:
	var military=preload("res://scripts/hud/military_roster_visuals.gd")
	var saved:=GameState.elapsed_days;GameState.elapsed_days=71*365
	assert_str(military.illustration_path("levy")).is_equal(military.EARLY_UNITS.levy)
	assert_str(military.illustration_path("spearman")).is_equal(military.EARLY_UNITS.spearman)
	assert_str(military.illustration_path("rifle_infantry")).is_equal(String(military.manifest().rifle_infantry.path))
	assert_str(military.illustration_path("unknown_legacy_type")).is_empty()
	GameState.elapsed_days=300*365
	assert_str(military.illustration_path("levy")).is_equal(String(military.manifest().levy.path))
	GameState.elapsed_days=saved

func test_early_research_keeps_subject_identity_visibility_and_later_mapping()->void:
	var research=preload("res://scripts/hud/research_visuals.gd")
	var saved:=GameState.elapsed_days;GameState.elapsed_days=71*365
	var paths:Dictionary={}
	for id:String in research.EARLY_SUBJECTS:
		var item:={"id":id,"exposed":true}
		var path:String=research.subject_art_key(item)
		assert_bool(ResourceLoader.exists(path)).is_true()
		assert_bool(paths.has(path)).is_false();paths[path]=true
		assert_bool(research.focus_for(item).y>.6).is_true()
		item.exposed=false
		assert_str(research.subject_art_key(item)).is_empty()
	GameState.elapsed_days=300*365
	assert_str(research.subject_art_key({"id":"oral_epics"})).is_equal(String(research.manifest().oral_epics.path))
	GameState.elapsed_days=saved

func test_wonder_plates_match_catalogue_without_changing_it()->void:
	var art=preload("res://scripts/hud/undertaking_art.gd")
	var catalog=preload("res://scripts/undertaking_catalog.gd")
	var saved:=GameState.elapsed_days;GameState.elapsed_days=71*365
	var regions:Dictionary={}
	assert_int(art.IDS.size()).is_equal(catalog.all().size())
	for definition:Dictionary in catalog.all():
		var plate:=art.texture(String(definition.id)) as AtlasTexture
		assert_object(plate).is_not_null()
		assert_bool(Rect2(Vector2.ZERO,plate.atlas.get_size()).grow(.1).encloses(plate.region)).is_true()
		var key:=plate.atlas.resource_path+str(plate.region)
		assert_bool(regions.has(key)).is_false();regions[key]=true
	assert_object(art.texture("not_a_wonder")).is_null()
	GameState.elapsed_days=300*365
	assert_object(art.texture("ancestor_ring")).is_null()
	GameState.elapsed_days=saved
