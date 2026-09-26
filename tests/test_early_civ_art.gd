extends GdUnitTestSuite
const Art:=preload("res://scripts/hud/early_civ_art.gd")
const Person:=preload("res://scripts/hud/person_portrait.gd")
func test_new_world_uses_available_families_before_repeating()->void:
	var identity=preload("res://scripts/character_appearance.gd")
	for seed_value in [0,82,-718]:
		var seen:Dictionary={}
		for index in identity.FAMILIES.size():
			var owner:="player" if index==0 else "civ_%02d"%index
			var family:String=identity.initial_family(seed_value,owner)
			assert_bool(seen.has(family)).is_false();seen[family]=true
func test_expanding_library_keeps_existing_government_and_diplomatic_family()->void:
	var identity=preload("res://scripts/character_appearance.gd")
	var records:Array=[{"early_art_profile":"reedwake"}]
	assert_str(identity.family_for(982,"unused_appearance_fixture",records)).is_equal("reedwake")
	var saved:Dictionary=ForeignDiplomacy.leaders.duplicate(true)
	var saved_seed:=ForeignDiplomacy.seed_value;ForeignDiplomacy.seed_value=998
	ForeignDiplomacy.leaders["unused_appearance_fixture"]={"early_art_profile":"windseam"}
	assert_str(identity.family_for(999,"unused_appearance_fixture")).is_equal(identity.initial_family(999,"unused_appearance_fixture"))
	ForeignDiplomacy.seed_value=999
	assert_str(identity.family_for(999,"unused_appearance_fixture")).is_equal("windseam")
	var visitor:={"name":"Illustrated envoy"}
	Art.bind_foreign_identity(visitor,"unused_appearance_fixture",999)
	assert_str(visitor.early_art_profile).is_equal("windseam")
	ForeignDiplomacy.leaders=saved;ForeignDiplomacy.seed_value=saved_seed
func test_all_fourteen_directions_have_distinct_early_scenes()->void:
	var saved:=GameState.elapsed_days;GameState.elapsed_days=0
	var seen:Dictionary={}
	for index in 14:
		var texture:=preload("res://scripts/hud/ambition_art.gd").texture(index) as AtlasTexture
		var key:=str(texture.atlas.resource_path)+str(texture.region)
		assert_bool(seen.has(key)).is_false();seen[key]=true
		assert_bool(texture.region.end.x<=texture.atlas.get_width()).is_true()
		assert_bool(texture.region.end.y<=texture.atlas.get_height()).is_true()
	GameState.elapsed_days=300*365
	var later:=preload("res://scripts/hud/ambition_art.gd").texture(13) as AtlasTexture
	assert_str(later.atlas.resource_path).is_equal("res://assets/ui/ambition_atlas_v1.png")
	GameState.elapsed_days=saved
func test_foreign_leader_keeps_own_identity_through_save_and_temperament_changes()->void:
	var person:={"name":"Arven", "temperament":"Practical organizer"}
	Art.bind_foreign_identity(person,"rival_9",82)
	var family:String=person.early_art_profile;var slot:int=person.early_art_index
	var restored:Dictionary=JSON.parse_string(JSON.stringify(person))
	restored.temperament="Proud guardian"
	Art.bind_foreign_identity(restored,"rival_9",82)
	assert_str(Art.owner(restored)).is_equal("rival_9")
	assert_str(restored.early_art_profile).is_equal(family)
	assert_int(int(restored.early_art_index)).is_equal(slot)
	assert_bool(person.has("personality")).is_false()
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
func test_character_widget_fills_its_frame_instead_of_stretching()->void:
	# The painting keeps its aspect and fills the frame (cover): no stretching,
	# and no blank band above or below it (ART_DIRECTION problem 7).
	var saved:=GameState.elapsed_days;GameState.elapsed_days=365
	var image:=Person.picture({"person_id":3,"name":"Known steward"},150,150)
	assert_int(image.stretch_mode).is_equal(TextureRect.STRETCH_KEEP_ASPECT_COVERED)
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
	for id:String in military.EARLY_UNITS:
		assert_bool(ResourceLoader.exists(military.illustration_path(id))).is_true()
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
		var focus:Vector2=research.focus_for(item)
		assert_bool(focus.x>=0 and focus.x<=1 and focus.y>=0 and focus.y<=1).is_true()
		item.exposed=false
		assert_str(research.subject_art_key(item)).is_empty()
	GameState.elapsed_days=300*365
	assert_str(research.subject_art_key({"id":"oral_epics"})).is_equal(String(research.manifest().oral_epics.path))
	GameState.elapsed_days=saved

func test_first300_research_cards_are_distinct_and_era_scoped()->void:
	var research=preload("res://scripts/hud/research_visuals.gd")
	var saved:=GameState.elapsed_days;GameState.elapsed_days=71*365
	var seen:Dictionary={}
	var bindings:Dictionary=research.first300_manifest()
	assert_bool(bindings.size()>=36).is_true()
	for id:String in bindings:
		var path:=research.subject_art_key({"id":id,"exposed":true})
		assert_str(path).is_equal(String(bindings[id]))
		assert_bool(ResourceLoader.exists(path)).is_true()
		var texture:=research.for_discovery({"id":id,"exposed":true})
		assert_object(texture).is_not_null()
		var cell_key:=path
		if texture is AtlasTexture:
			var card:=texture as AtlasTexture
			assert_bool(card.region.position.x>=0 and card.region.position.y>=0).is_true()
			assert_bool(card.region.end.x<=card.atlas.get_width() and card.region.end.y<=card.atlas.get_height()).is_true()
			cell_key=str(card.atlas.resource_path)+str(card.region)
		assert_bool(seen.has(cell_key)).is_false();seen[cell_key]=true
	for modern_id in ["teleprinter_mechanisms","mechanical_washing_machines","rolling_element_bearings","jet_propulsion"]:
		assert_bool(bindings.has(modern_id)).is_false()
	GameState.elapsed_days=300*365
	assert_bool(research.subject_art_key({"id":"grain_malting"}).ends_with(".tres")).is_false()
	GameState.elapsed_days=saved

func test_wonder_plates_match_catalogue_without_changing_it()->void:
	var art=preload("res://scripts/hud/undertaking_art.gd")
	var catalog=preload("res://scripts/undertaking_catalog.gd")
	var saved:=GameState.elapsed_days;GameState.elapsed_days=71*365
	var regions:Dictionary={}
	# Plates cover the founding-era works; later Great Works have none yet.
	for id:String in art.IDS:assert_dict(catalog.get_definition(id)).is_not_empty()
	for definition:Dictionary in catalog.all().filter(func(d):return d.id in art.IDS):
		var plate:=art.texture(String(definition.id)) as AtlasTexture
		assert_object(plate).is_not_null()
		assert_bool(Rect2(Vector2.ZERO,plate.atlas.get_size()).grow(.1).encloses(plate.region)).is_true()
		var key:=plate.atlas.resource_path+str(plate.region)
		assert_bool(regions.has(key)).is_false();regions[key]=true
	assert_object(art.texture("not_a_wonder")).is_null()
	GameState.elapsed_days=300*365
	assert_object(art.texture("ancestor_ring")).is_null()
	GameState.elapsed_days=saved

func test_saved_family_name_prevents_recasting_when_seed_or_library_order_changes()->void:
	var person:={"early_art_profile":"windseam","early_art_index":2,"person_id":9,"appearance_civ_id":"player","appearance_world_seed":1}
	assert_int(Art.profile(person)).is_equal(Art.PROFILES.find("windseam"))
	var restored:Dictionary=JSON.parse_string(JSON.stringify(person));restored.appearance_world_seed=999
	assert_int(Art.profile(restored)).is_equal(Art.profile(person))
func test_people_shown_together_never_share_a_painting()->void:
	# Six faces that would all draw the same cell get six different paintings,
	# and the same person keeps the same slot within one screen.
	var saved:=GameState.elapsed_days;GameState.elapsed_days=365
	var people:Array=[]
	for i in 6:people.append({"name":"Face %d" % i,"person_id":0,"portrait_index":0})
	var slots:=Person.distinct_slots(people)
	var seen:Dictionary={}
	for slot:Array in slots:seen[str(slot)]=true
	assert_int(seen.size()).is_equal(6)
	var registry:Dictionary={}
	var first:=Person.claim(registry,people[0])
	assert_array(Person.claim(registry,people[1])).is_not_equal(first)
	assert_array(Person.claim(registry,people[0])).is_equal(first)
	GameState.elapsed_days=saved
