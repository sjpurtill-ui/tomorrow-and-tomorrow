extends GdUnitTestSuite
## The people taste the water they come to: the sea is known for salt at
## once, and the survey card never says nobody has judged it.

const Terrain:=preload("res://scripts/local_terrain.gd")
const Survey:=preload("res://scripts/hud/resource_survey_card.gd")

func after_test()->void:
	GameState.settlement_site_committed=false
	GameState.water_metrics={}

func test_the_sea_is_known_for_salt_and_where_they_drink_is_said()->void:
	var terrain:Node3D=auto_free(Terrain.new())
	GameState.settlement_site_committed=false
	assert_str(terrain.open_water_words()).contains("not fit to drink")
	GameState.settlement_site_committed=true
	GameState.settlement_name="Ashleyfire"
	GameState.water_metrics={"source_accessible":true,"source_kind":"river","source_distance_km":0.4}
	var words:String=terrain.open_water_words()
	assert_str(words).contains("Salt water")
	assert_str(words).contains("They drink from the river, 0.4 km from Ashleyfire.")
	assert_str(words).not_contains("Nobody")

func test_the_card_shows_what_the_water_is()->void:
	var card:Control=auto_free(Survey.new())
	add_child(card)
	card.show_survey([],{"id":"water","label":"open water","water_words":"Salt water: the sea."},{})
	var found:=false
	for label in card.find_children("*","Label",true,false):
		if (label as Label).text.contains("Salt water"):found=true
		assert_str((label as Label).text).not_contains("Nobody has yet said")
	assert_bool(found).is_true()
