extends GdUnitTestSuite
const Card=preload("res://scripts/hud/resource_survey_card.gd")
class ClimateTerrain extends "res://scripts/local_terrain.gd":
	var precipitation:=.25
	func _climate_at(_x:float,_z:float,_height:float)->Dictionary:
		return {"temperature":.8,"precipitation":precipitation,"river_distance":100.0}

func test_unknown_quality_is_not_replaced_with_invented_numbers()->void:
	var card:ScrollContainer=auto_free(Card.new());add_child(card)
	var entries:Array=[{"id":"clay","resource":"Clay","distance_km":2.0,"knowledge":"indicated","quality":"unknown","abundance":"unknown","retrievable":false,"blockers":["deposit has not been surveyed"]}]
	card.show_survey(entries,{"id":"steppe","label":"sun-scoured drylands","tree_cover":0,"stone":"limited","soil":"low","fiber":"sparse"})
	assert_str(card.surface_values.wood.text).is_equal("0%")
	assert_str(card.resource_cards[0].quality).is_equal("unknown")
	assert_str(card.resource_cards[0].abundance).is_equal("unknown")
	assert_bool(card.resource_cards[0].detail.visible).is_false()
	card.resource_cards[0].expand.pressed.emit()
	assert_bool(card.resource_cards[0].detail.visible).is_true()
	assert_array(card.snapshot.entries).is_equal(entries)

func test_survey_cards_fit_narrow_map_panel_and_scroll_full_details()->void:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(800,600);add_child(viewport)
	var panel:=PanelContainer.new();viewport.add_child(panel)
	var card:=Card.new();panel.add_child(card);card.host_panel=panel
	var entries:Array=[]
	for i in 12:entries.append({"id":str(i),"resource":"Clay","distance_km":i,"knowledge":"surveyed","quality":"good","abundance":"common","retrievable":true,"blockers":[]})
	card.show_survey(entries,{"id":"steppe","label":"sun-scoured drylands","tree_cover":0,"stone":"limited","soil":"low","fiber":"sparse"})
	for i in 5:await get_tree().process_frame
	assert_float(panel.size.x).is_less_equal(360)
	assert_float(panel.size.y).is_less_equal(410)
	assert_float(card.get_h_scroll_bar().max_value).is_less_equal(card.size.x+1)
	assert_float(card.get_v_scroll_bar().max_value).is_greater(card.size.y)

func test_one_source_survey_uses_dense_rows_instead_of_tall_metric_cards()->void:
	var viewport:SubViewport=auto_free(SubViewport.new());viewport.size=Vector2i(1024,640);add_child(viewport)
	var panel:=PanelContainer.new();viewport.add_child(panel)
	var card:=Card.new();panel.add_child(card);card.host_panel=panel
	card.show_survey([{"id":"soil","resource":"Fertile Soil","distance_km":18.0,"knowledge":"surveyed","quality":"good","abundance":"common","retrievable":true,"blockers":[]}],{"id":"steppe","label":"sun-scoured drylands","tree_cover":0,"stone":"scattered","soil":"low","fiber":"scattered"},{"title":"NO USABLE WATER CONFIRMED","source_text":"Fresh water · not confirmed","reason":"No returned report confirms drinking water.","neighbors":{"title":"NO KNOWN NEIGHBOR","text":"Returned reports only."},"color":Color("d77e6b")})
	for i in 3:await get_tree().process_frame
	assert_float(panel.size.x).is_less_equal(360)
	assert_float(panel.size.y).is_less_equal(290)
	assert_float(card.resource_cards[0].card.get_combined_minimum_size().y).is_less_equal(38)
	assert_str(card.resource_cards[0].expand.text).is_equal("›")

func test_dryland_visual_matches_climate_without_changing_its_resources()->void:
	var terrain:Node3D=auto_free(ClimateTerrain.new())
	terrain.detail_noise=FastNoiseLite.new()
	var dry:Dictionary=terrain._biome_at(0,0,1.5)
	assert_str(dry.id).is_equal("steppe")
	assert_float(dry.woodland).is_equal(0.0)
	assert_float(dry.fertility).is_equal(.14)
	assert_float(dry.color.r-dry.color.g).is_greater(.055)
	terrain.precipitation=.55
	var wet:Dictionary=terrain._biome_at(0,0,1.5)
	assert_float(wet.color.g-wet.color.r).is_greater(0)
	assert_float(wet.fertility).is_greater(dry.fertility)
