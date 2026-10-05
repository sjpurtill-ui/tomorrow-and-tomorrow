extends GdUnitTestSuite
## A year is named after a discovery only when it is a landmark of the
## people's making (copper, the wheel, writing), told as what happened and
## only once; an ordinary practice never names a year. A quiet year may say
## how the people grew.

const Annals:=preload("res://scripts/chronicle_annals.gd")

func test_only_a_landmark_names_a_year()->void:
	assert_str(Annals.landmark_name("Cast copper weapons")).is_equal("the year copper came")
	assert_str(Annals.landmark_name("Spoked wheel")).is_equal("the year the wheel came")
	assert_str(Annals.landmark_name("Pest barrier maintenance")).is_empty()
	assert_str(Annals.landmark_name("Skin lotion")).is_empty()
	assert_str(Annals.landmark_name("Bowl carving")).is_empty()

func test_an_ordinary_learning_year_has_no_name_and_a_landmark_is_named_once()->void:
	var a:=Annals._new_acc(70)
	(a.firsts as Array).append("Pest barrier maintenance")
	(a.learned as Array).append("Refuse pit rotation")
	assert_str(String(Annals._name_year(a,[]).name)).is_empty()
	(a.learned as Array).append("Cast copper weapons")
	assert_str(String(Annals._name_year(a,[]).name)).is_equal("the year copper came")
	assert_str(String(Annals._name_year(a,[{"name":"the year copper came"}]).name)).is_empty()

func test_a_quiet_year_is_never_titled_by_a_practice()->void:
	var a:=Annals._new_acc(70)
	for name in ["Pest barrier maintenance","Token envelopes"]:(a.learned as Array).append(name)
	assert_str(Annals._quiet_title(a,1,[])).not_contains("ear of")

func test_older_years_named_for_a_practice_are_shown_unnamed()->void:
	assert_str(Annals.display_name({"name":"the year of pest barrier maintenance","glyph":"discovery"})).is_empty()
	assert_str(Annals.display_name({"name":"the year of cast copper weapons","glyph":"discovery"})).is_equal("the year copper came")
	# Other names stay as they were.
	assert_str(Annals.display_name({"name":"the year Chomomi died","glyph":"death"})).is_equal("the year Chomomi died")
