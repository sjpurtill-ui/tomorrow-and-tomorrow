extends GdUnitTestSuite
const Art=preload("res://scripts/hud/research_visuals.gd")
func before_test()->void:
	GameState.reset_for_new_world(424242);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
func test_every_named_discovery_has_its_own_present_image_and_no_duplicate_file()->void:
	var paths:Dictionary={};var hashes:Dictionary={}
	for item:Dictionary in DiscoverySystem.technology_catalog:
		var path:=Art.subject_art_key(item)
		assert_str(path).override_failure_message(item.id).is_not_empty()
		assert_bool(ResourceLoader.exists(path)).override_failure_message("Missing subject art: "+item.id).is_true()
		assert_bool(paths.has(path)).override_failure_message("Reused assignment: "+item.id).is_false();paths[path]=item.id
		if not FileAccess.file_exists(path):continue
		var fingerprint:=FileAccess.get_sha256(path)
		assert_bool(hashes.has(fingerprint)).override_failure_message("Same painting copied to another filename: "+item.id).is_false();hashes[fingerprint]=item.id
	assert_int(paths.size()).is_equal(DiscoverySystem.technology_catalog.size())
func test_hidden_subjects_never_reveal_their_painting_and_unknown_ids_get_no_category_fallback()->void:
	for item:Dictionary in DiscoverySystem.technology_catalog:
		var hidden:=item.duplicate();hidden.exposed=false
		assert_str(Art.subject_art_key(hidden)).is_empty();assert_object(Art.for_discovery(hidden)).is_null()
	assert_object(Art.for_discovery({"id":"not_authored","domain":"culture","exposed":true})).is_null()
func test_storytelling_stone_and_pottery_have_different_subjects_and_preserve_discovery_data()->void:
	var stone:=Art.for_discovery({"id":"stone_sorting"})
	var clay:=Art.for_discovery({"id":"clay_shaping"})
	var oral:=Art.for_discovery({"id":"oral_epics"})
	assert_str(stone.resource_path).ends_with("stone-selection-v1.png")
	assert_str(clay.resource_path).ends_with("clay_shaping-v1.png")
	assert_str(oral.resource_path).ends_with("oral_epics-v2.png")
	assert_str(DiscoverySystem.catalog_by_id.oral_epics.name).is_equal("Oral Epics")
	assert_float(float(DiscoverySystem.catalog_by_id.oral_epics.effects.knowledge_preservation)).is_equal(.05)
	assert_float(float(DiscoverySystem.catalog_by_id.oral_epics.effects.cohesion)).is_equal(.04)
func test_subject_crop_preserves_aspect_and_stays_inside_the_image()->void:
	var item:={"id":"oral_epics"};var texture:=Art.for_discovery(item)
	for target:Vector2 in [Vector2(708,210),Vector2(250,104),Vector2(264,70),Vector2(120,220)]:
		var region:=Art.crop_region(texture,target,Art.focus_for(item))
		assert_bool(Rect2(Vector2.ZERO,texture.get_size()).grow(.01).encloses(region)).is_true()
		assert_float(region.size.x/region.size.y).is_equal_approx(target.x/target.y,.0001)
		assert_bool(region.has_point(texture.get_size()*Art.focus_for(item))).is_true()
func test_texture_cache_is_bounded_when_browsing_the_full_catalogue()->void:
	for item:Dictionary in DiscoverySystem.technology_catalog:Art.for_discovery(item)
	assert_int(Art.textures.size()).is_less_equal(Art.CACHE_LIMIT)

func test_every_land_sea_and_air_type_has_a_distinct_portrait()->void:
	var military=preload("res://scripts/hud/military_roster_visuals.gd")
	var ids:Array=preload("res://scripts/military_unit_catalog.gd").ARCHETYPES.keys()
	ids.append_array(preload("res://scripts/joint_force_catalog.gd").UNITS.keys())
	var paths:Dictionary={};var hashes:Dictionary={}
	for item:Dictionary in DiscoverySystem.technology_catalog:
		var path:=Art.subject_art_key(item)
		paths[path]=item.id
		if FileAccess.file_exists(path):hashes[FileAccess.get_sha256(path)]=item.id
	for id:String in ids:
		var path:String=military.illustration_path(id)
		assert_str(path).override_failure_message(id).is_not_empty()
		assert_bool(ResourceLoader.exists(path)).override_failure_message("Missing unit portrait: "+id).is_true()
		assert_bool(paths.has(path)).override_failure_message("Reused painting assignment: "+id).is_false();paths[path]=id
		if FileAccess.file_exists(path):
			var fingerprint:=FileAccess.get_sha256(path)
			assert_bool(hashes.has(fingerprint)).override_failure_message("Duplicate painting: "+id).is_false();hashes[fingerprint]=id
	assert_int(ids.size()).is_equal(87)
	assert_int(military.manifest().size()).is_equal(ids.size())
	assert_str(military.illustration_path("unknown_legacy_type")).is_empty()

func test_portrait_focal_point_and_unknown_report_are_respected()->void:
	var painter:Node=auto_free(preload("res://scripts/hud/military_roster_visuals.gd").new())
	var portrait:Control=auto_free(painter.portrait("levy","army"))
	assert_float(portrait.focus.y).is_equal(.35)
	var unknown:Control=auto_free(painter.portrait("levy","army",true))
	assert_str(unknown.tooltip_text).is_equal("Awaiting a formation report")
	assert_object(unknown.texture).is_not_same(portrait.texture)
	var fallback:Control=auto_free(painter.portrait("unknown_legacy_type","army"))
	assert_object(fallback.texture).is_null()
