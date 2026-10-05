extends GdUnitTestSuite
## Music by the game's mood (soundtrack.gd): each mood's folder holds its
## pieces; calm in peace, war in war; never the same piece twice running.

const Soundtrack:=preload("res://scripts/soundtrack.gd")

func after_test()->void:
	MilitaryCampaign.active_siege={}

func test_the_calm_mood_has_its_pieces_and_they_load()->void:
	var calm:=Soundtrack.pieces("calm")
	assert_bool(calm.has("res://assets/audio/score/calm/dry_hall_arpeggios.mp3")).is_true()
	for piece:String in calm:assert_object(load(piece) as AudioStream).override_failure_message(piece).is_not_null()

func test_never_the_same_piece_twice_running()->void:
	var list:=PackedStringArray(["a","b","c"])
	for roll in [0.0,0.4,0.99]:assert_str(Soundtrack.choose(list,"b",roll)).is_not_equal("b")
	assert_str(Soundtrack.choose(PackedStringArray(["a"]),"a",0.5)).is_equal("a")
	assert_str(Soundtrack.choose(PackedStringArray(),"",0.5)).is_empty()

func test_war_turns_the_mood()->void:
	MilitaryCampaign.active_siege={"days":3}
	assert_str(Soundtrack.mood_now()).is_equal("war")
	MilitaryCampaign.active_siege={}
	assert_str(Soundtrack.mood_now()).is_equal(Soundtrack.DEFAULT_MOOD)

func test_peace_after_first_contact_has_its_own_mood()->void:
	assert_bool(Soundtrack.pieces("contact").has("res://assets/audio/score/contact/tense_silences.mp3")).is_true()
	var civ:Dictionary=CivilizationSystem.civilizations[1] if CivilizationSystem.civilizations.size()>1 else {}
	if civ.is_empty():return
	var relation:Dictionary=civ.get("player_relation",{})
	var before:=int(relation.get("contact_level",0))
	relation["contact_level"]=1;civ["player_relation"]=relation
	assert_str(Soundtrack.mood_now()).is_equal("contact")
	relation["contact_level"]=before

func test_a_later_age_piece_waits_for_its_year()->void:
	var later:="res://assets/audio/score/calm/y500_sparse_pulse.mp3"
	assert_int(Soundtrack.from_year(later)).is_equal(500)
	assert_int(Soundtrack.from_year("res://assets/audio/score/calm/taut_bow.mp3")).is_equal(0)
	assert_bool(Soundtrack.pieces_for_year("calm",172).has(later)).is_false()
	assert_bool(Soundtrack.pieces_for_year("calm",172).has("res://assets/audio/score/calm/taut_bow.mp3")).is_true()
	assert_bool(Soundtrack.pieces_for_year("calm",500).has(later)).is_true()

func test_an_early_age_piece_stops_after_its_years()->void:
	var early:="res://assets/audio/score/calm/y1-200_espacio_silencio.mp3"
	assert_array(Soundtrack.years(early)).is_equal([1,200])
	assert_bool(Soundtrack.pieces_for_year("calm",1).has(early)).is_true()
	assert_bool(Soundtrack.pieces_for_year("calm",200).has(early)).is_true()
	assert_bool(Soundtrack.pieces_for_year("calm",201).has(early)).is_false()
