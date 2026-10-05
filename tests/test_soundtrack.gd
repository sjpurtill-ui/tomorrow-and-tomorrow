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
