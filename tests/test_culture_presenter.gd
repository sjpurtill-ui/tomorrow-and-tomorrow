extends GdUnitTestSuite
const Presenter:=preload("res://scripts/hud/culture_presenter.gd")
func test_empty_memory_does_not_invent_a_tendency()->void:
	assert_str(Presenter.tendency({})).is_empty()
	assert_str(Presenter.tendency({"mutual_aid":0,"fair_exchange":0})).is_empty()
func test_strongest_recorded_influence_is_named()->void:
	assert_str(Presenter.tendency({"mutual_aid":0.7,"fair_exchange":0.3})).is_equal("Mutual Aid")
func test_tied_influences_are_both_represented()->void:
	assert_str(Presenter.tendency({"mutual_aid":0.5,"fair_exchange":0.5,"exploitation":0})).is_equal("Mutual Aid / Fair Exchange")
