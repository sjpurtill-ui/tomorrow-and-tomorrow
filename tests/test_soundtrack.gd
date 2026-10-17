extends GdUnitTestSuite
## Music by the game's mood (soundtrack.gd): each mood's folder holds its
## pieces; calm in peace, war in war; never the same piece twice running.

const Soundtrack:=preload("res://scripts/soundtrack.gd")

func after_test()->void:
	MilitaryCampaign.active_siege={}

func test_the_calm_mood_has_its_pieces_and_they_load()->void:
	var calm:=Soundtrack.pieces("calm")
	assert_bool(calm.has("res://assets/audio/score/calm/y500-700_dry_hall_arpeggios.mp3")).is_true()
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
	assert_int(Soundtrack.from_year("res://assets/audio/score/calm/any_age.mp3")).is_equal(0)
	assert_bool(Soundtrack.pieces_for_year("calm",172).has(later)).is_false()
	assert_bool(Soundtrack.pieces_for_year("calm",172).has("res://assets/audio/score/calm/y1-200_click_clack_raw.mp3")).is_true()
	assert_bool(Soundtrack.pieces_for_year("calm",701).has("res://assets/audio/score/calm/y500-700_taut_bow.mp3")).is_false()
	assert_bool(Soundtrack.pieces_for_year("calm",500).has(later)).is_true()

func test_an_early_age_piece_stops_after_its_years()->void:
	var early:="res://assets/audio/score/calm/y1-200_espacio_silencio.mp3"
	assert_array(Soundtrack.years(early)).is_equal([1,200])
	assert_bool(Soundtrack.pieces_for_year("calm",1).has(early)).is_true()
	assert_bool(Soundtrack.pieces_for_year("calm",200).has(early)).is_true()
	assert_bool(Soundtrack.pieces_for_year("calm",201).has(early)).is_false()

func test_an_any_mood_piece_joins_every_mood_in_its_years()->void:
	var any:="res://assets/audio/score/any/y2800-3000_pot_rhythms.mp3"
	for mood in Soundtrack.MOODS:
		assert_bool(Soundtrack.pieces_for_year(mood,2900).has(any)).override_failure_message(mood).is_true()
		assert_bool(Soundtrack.pieces_for_year(mood,2799).has(any)).is_false()


func test_added_espacio_takes_load_only_in_the_early_calm_pool()->void:
	for take:String in ["ii","iii"]:
		var path:="res://assets/audio/score/calm/y1-200_espacio_silencio_"+take+".mp3"
		var stream:=load(path) as AudioStream
		assert_object(stream).is_not_null()
		assert_float(stream.get_length()).is_greater(60.0)
		assert_bool(Soundtrack.pieces_for_year("calm",1).has(path)).is_true()
		assert_bool(Soundtrack.pieces_for_year("calm",200).has(path)).is_true()
		assert_bool(Soundtrack.pieces_for_year("calm",201).has(path)).is_false()
		assert_bool(Soundtrack.pieces_for_year("war",1).has(path)).is_false()

class CueProbe extends Soundtrack:
	var now:=0.0
	var cues:=0
	func _seconds()->float:return now
	func play_next()->void:cues+=1

func test_rotation_waits_five_minutes_and_never_cuts_a_playing_piece()->void:
	var probe:=CueProbe.new();auto_free(probe)
	var score:=AudioStreamPlayer.new();auto_free(score);add_child(score)
	probe.player=score
	probe._next_check=10000.0
	probe._next_cue=Soundtrack.GAP_MIN
	assert_float(Soundtrack.GAP_MIN).is_equal(300.0)
	assert_float(Soundtrack.GAP_MAX).is_equal(300.0)
	probe.now=299.0;probe._process(0.0)
	assert_int(probe.cues).is_equal(0)
	probe.now=300.0;probe._process(0.0)
	assert_int(probe.cues).is_equal(1)
	score.stream=load("res://assets/audio/score/calm/y1-200_espacio_silencio_ii.mp3")
	score.play()
	assert_bool(score.playing).is_true()
	probe.now=400.0;probe._process(0.0)
	assert_int(probe.cues).is_equal(1)
	score.stop();probe._process(0.0)
	assert_int(probe.cues).is_equal(2)
