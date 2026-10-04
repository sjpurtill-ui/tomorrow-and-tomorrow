extends GdUnitTestSuite
const Stage:=preload("res://scripts/hud/court_stage.gd")

func test_words_clear_the_speaker_when_earlier_dialogue_occupies_the_space_above()->void:
	var bounds:=Rect2(4,24,792,332)
	var head:=Rect2(350,132,96,90)
	var earlier:=Rect2(190,30,400,80)
	var bubble:=Rect2(250,100,300,70)
	bubble.position=Stage.clear_bubble_position(bubble,bounds,[earlier,head])
	assert_bool(bounds.encloses(bubble)).is_true()
	assert_bool(bubble.intersects(head)).is_false()
	assert_bool(bubble.intersects(earlier)).is_false()

func test_a_clear_bubble_does_not_move_and_repeated_placement_is_stable()->void:
	var bounds:=Rect2(4,24,1272,500)
	var bubble:=Rect2(480,50,310,72)
	var obstacles:Array[Rect2]=[Rect2(600,160,100,80),Rect2(20,30,300,80)]
	var first:=Stage.clear_bubble_position(bubble,bounds,obstacles)
	assert_vector(first).is_equal(bubble.position)
	bubble.position=first
	assert_vector(Stage.clear_bubble_position(bubble,bounds,obstacles)).is_equal(first)

func test_constrained_speech_remains_inside_the_view()->void:
	var bounds:=Rect2(4,24,632,212)
	var bubble:=Rect2(-10,150,610,200)
	var placed:=Rect2(Stage.clear_bubble_position(bubble,bounds,[Rect2(280,100,100,100)]),bubble.size)
	assert_bool(bounds.encloses(placed)).is_true()
