extends "res://tests/test_society_exchange.gd"
const Art=preload("res://scripts/hud/artifact_visuals.gd")
const Early=preload("res://scripts/early_civ_artifacts.gd")
const Catalogue=preload("res://scripts/artifact_collection.gd")

func test_artwork_uses_exact_catalogue_identity_and_preserves_legacy_fallback()->void:
	assert_str(Art.image_path({"kind":"artifact","artifact_origin":"prehistoric","art_collection":"prehistoric-v1","source_id":"","catalogue_id":0})).is_equal("res://assets/ui/artifacts/prehistoric-v1/artifact-0000.png")
	assert_str(Art.image_path({"kind":"artifact","name":"Flint cutting blade"})).is_empty()
	assert_str(Art.image_path({"kind":"knowledge","catalogue_id":0})).is_empty()
	assert_str(Art.image_path({"kind":"artifact","artifact_origin":"prehistoric","art_collection":"prehistoric-v1","source_id":"","catalogue_id":4096})).is_empty()
	assert_str(Art.image_path({"kind":"artifact","artifact_origin":"prehistoric","art_collection":"prehistoric-v1","source_id":"","catalogue_id":-1})).is_empty()

func test_approved_art_loads_and_pending_art_does_not_impersonate_another()->void:
	var resource:=Art.texture({"kind":"artifact","artifact_origin":"prehistoric","art_collection":"prehistoric-v1","source_id":"","catalogue_id":0})
	assert_bool(resource is Texture2D).is_true()
	assert_int(resource.get_width()).is_less_equal(512)
	assert_int(resource.get_height()).is_equal(resource.get_width())
	for index:int in range(4096):
		var path:=Art.image_path({"kind":"artifact","artifact_origin":"prehistoric","art_collection":"prehistoric-v1","source_id":"","catalogue_id":index})
		if not path.is_empty():assert_str(path).is_equal("res://assets/ui/artifacts/prehistoric-v1/artifact-%04d.png" % index)
	assert_int(Art.textures.size()).is_less_equal(Art.CACHE_LIMIT)

func test_illustrated_collection_stays_inside_small_and_large_viewports()->void:
	var record:=Catalogue.find_at(777,Vector2(10,10),1);record.catalogue_id=0
	record.insight="A rough hollow holds fuel beside a wick, suggesting a portable source of light that can be studied and improved."
	E.data().collections[record.id]=record
	for shape:Vector2i in [Vector2i(340,640),Vector2i(960,720)]:
		var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=shape;add_child(viewport)
		var sheet:=CollectionPanel.new();viewport.add_child(sheet)
		for frame:int in range(4):await get_tree().process_frame
		assert_float(sheet.panel.size.x).is_less_equal(shape.x)
		assert_float(sheet.panel.size.y).is_less_equal(shape.y)
		var artwork:TextureRect
		for node:Node in sheet.find_children("*","TextureRect",true,false):
			if node.custom_minimum_size.y==240:artwork=node;break
		assert_bool(is_instance_valid(artwork)).is_true()
		if is_instance_valid(artwork):
			assert_bool(artwork.texture is Texture2D).is_true()
			assert_float(artwork.size.x).is_less_equal(sheet.panel.size.x)

func test_civilization_art_cannot_leak_into_ancient_finds()->void:
	var record:=Catalogue.find_at(777,Vector2(10,10),1);record.catalogue_id=0
	assert_str(record.artifact_origin).is_equal("prehistoric")
	assert_str(record.art_collection).is_equal("prehistoric-v1")
	record.art_collection="early-civ-v1"
	assert_str(Art.image_path(record)).is_empty()
	assert_bool(E.valid_item(record)).is_false()
	record.artifact_origin="civilization";record.source_id="neighbor";record.maker_requirements=Early.REQUIREMENTS[0].duplicate()
	assert_str(Art.image_path(record)).is_equal("res://assets/ui/artifacts/early-civ-v1/artifact-0000.png")
	assert_bool(E.valid_item(record)).is_true()

func test_living_craft_art_requires_real_source_and_adopted_discoveries()->void:
	var record:=item("pit_firing","artifact")
	Early.apply(record,["pit_firing"],{"pit_firing":1.0})
	assert_bool(record.has("art_collection")).is_false()
	var known:Array=Early.REQUIREMENTS[3].duplicate();var adopted:Dictionary={}
	for id:String in known:adopted[id]=1.0
	adopted.clay_tempering=.1;Early.apply(record,known,adopted)
	assert_bool(record.has("art_collection")).is_false()
	adopted.clay_tempering=.5;Early.apply(record,known,adopted)
	assert_str(record.art_collection).is_equal("early-civ-v1")
	assert_int(record.catalogue_id).is_equal(3)
	assert_bool(E.valid_item(record)).is_true()
	record.source_id="";record.erase("art_collection");Early.apply(record,known,adopted)
	assert_bool(record.has("art_collection")).is_false()

func test_all_exploration_variants_are_prehistoric_and_have_early_evidence()->void:
	const Ancient=preload("res://scripts/prehistoric_artifacts.gd")
	for id:int in range(4096):
		var definition:=Ancient.definition(id)
		assert_str(definition.artifact_origin).is_equal("prehistoric")
		assert_str(definition.art_collection).is_equal("prehistoric-v1")
		assert_bool(definition.discovery_id in ["stone_sorting","controlled_flaking","oral_epics","tallies","clay_shaping","charcoal"]).is_true()
		assert_bool(not DiscoverySystem.discovery_definition(definition.discovery_id).is_empty()).is_true()

func test_authored_experiments_preserve_specific_insights()->void:
	const Ancient=preload("res://scripts/prehistoric_artifacts.gd")
	var lamp:=Ancient.definition(161)
	assert_str(lamp.name).is_equal("Night in a hollow stone")
	assert_str(lamp.insight).contains("portable source of light")
	lamp.name="changed local copy"
	assert_str(Ancient.definition(161).name).is_equal("Night in a hollow stone")
	assert_bool(Ancient.definition(159).has("insight")).is_false()

func test_experiment_insight_survives_serialization_and_rejects_invalid_values()->void:
	const Ancient=preload("res://scripts/prehistoric_artifacts.gd")
	var record:=Catalogue.find_at(777,Vector2(10,10),1)
	record.merge(Ancient.definition(161),true)
	var restored:Dictionary=bytes_to_var(var_to_bytes(record))
	assert_bool(E.valid_item(restored)).is_true()
	assert_str(restored.insight).is_equal(record.insight)
	restored.insight="x".repeat(601)
	assert_bool(E.valid_item(restored)).is_false()
	restored.insight={"unexpected":"object"}
	assert_bool(E.valid_item(restored)).is_false()
