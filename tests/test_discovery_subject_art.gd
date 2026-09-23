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
		assert_bool(hashes.has(fingerprint)).override_failure_message("Same painting copied under another name: "+item.id).is_false();hashes[fingerprint]=item.id
	assert_int(paths.size()).is_equal(DiscoverySystem.technology_catalog.size())
	assert_int(Art.manifest().size()).is_equal(paths.size())
func test_hidden_subjects_and_unknown_ids_get_no_category_fallback()->void:
	for item:Dictionary in DiscoverySystem.technology_catalog:
		var hidden:=item.duplicate();hidden.exposed=false
		assert_str(Art.subject_art_key(hidden)).is_empty();assert_object(Art.for_discovery(hidden)).is_null()
	assert_object(Art.for_discovery({"id":"not_authored","domain":"culture","exposed":true})).is_null()
func test_storytelling_stone_and_pottery_are_distinct_without_changing_discovery_data()->void:
	assert_str(Art.for_discovery({"id":"stone_sorting"}).resource_path).ends_with("stone-selection-v1.png")
	assert_str(Art.for_discovery({"id":"clay_shaping"}).resource_path).ends_with("clay_shaping-v1.png")
	assert_str(Art.for_discovery({"id":"oral_epics"}).resource_path).ends_with("oral_epics-v2.png")
	assert_str(DiscoverySystem.catalog_by_id.oral_epics.name).is_equal("Oral Epics")
	assert_float(float(DiscoverySystem.catalog_by_id.oral_epics.effects.knowledge_preservation)).is_equal(.05)
	assert_float(float(DiscoverySystem.catalog_by_id.oral_epics.effects.cohesion)).is_equal(.04)
func test_subject_crop_keeps_target_aspect_inside_portrait_and_landscape_images()->void:
	var texture:=Art.for_discovery({"id":"oral_epics"})
	var source:=Rect2(Vector2.ZERO,texture.get_size())
	for size:Vector2 in [Vector2(708,210),Vector2(250,148),Vector2(264,70),Vector2(120,220)]:
		for focus:Vector2 in [Vector2(.5,.5),Vector2(0,0),Vector2(1,1)]:
			var crop:=Art.crop_region(texture,size,focus)
			assert_bool(source.grow(.01).encloses(crop)).is_true()
			assert_float(crop.size.x/crop.size.y).is_equal_approx(size.x/size.y,.0001)
			assert_bool(is_equal_approx(crop.size.x,source.size.x) or is_equal_approx(crop.size.y,source.size.y)).is_true()
func test_full_catalogue_browsing_bounds_cached_images_and_import_resolution()->void:
	for item:Dictionary in DiscoverySystem.technology_catalog:
		var texture:=Art.for_discovery(item)
		assert_object(texture).override_failure_message(item.id).is_not_null()
		if texture:assert_float(maxf(texture.get_width(),texture.get_height())).override_failure_message(item.id).is_less_equal(768.0)
	assert_int(Art.textures.size()).is_less_equal(Art.CACHE_LIMIT)
