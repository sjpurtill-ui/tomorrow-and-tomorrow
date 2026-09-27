extends GdUnitTestSuite
## Map lettering eases in and out (codex/map-motion): no popping cards at
## zoom thresholds, short slides for layout changes, nothing moving at rest.
const Fade:=preload("res://scripts/hud/presence_fade.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

func after_test()->void:
	Motion.reduce_motion=false

func _card(id:String,anchor:Vector2,offset:Vector2)->Dictionary:
	return {"id":id,"anchor":anchor,"rect":Rect2(anchor+offset,Vector2(80,24))}

func test_new_card_fades_in_monotonically_then_settles()->void:
	var fades:={}
	var present:={"a":_card("a",Vector2(100,100),Vector2(10,-30))}
	var previous:=-1.0
	var frames:=0
	while Fade.advance(fades,present,1.0/60.0) and frames<120:
		var a:=Fade.alpha(fades,"a")
		assert_bool(a>=previous and a<=1.0).is_true()
		previous=a
		frames+=1
	assert_float(Fade.alpha(fades,"a")).is_equal(1.0)
	assert_int(frames).is_less(20)  # about a fifth of a second
	# Settled: nothing moves, nothing to redraw.
	assert_bool(Fade.advance(fades,present,1.0/60.0)).is_false()

func test_leaving_card_fades_out_and_is_forgotten()->void:
	var fades:={}
	var present:={"a":_card("a",Vector2(100,100),Vector2(10,-30))}
	for i in 30:Fade.advance(fades,present,1.0/60.0)
	var frames:=0
	while Fade.advance(fades,{},1.0/60.0) and frames<120:
		assert_int(Fade.leaving(fades,{}).size()).is_equal(1)
		frames+=1
	assert_int(frames).is_less(15)
	assert_bool(fades.is_empty()).is_true()

func test_layout_jump_slides_relative_to_the_pin()->void:
	var fades:={}
	var anchor:=Vector2(200,200)
	for i in 30:Fade.advance(fades,{"a":_card("a",anchor,Vector2(10,-30))},1.0/60.0)
	# The card moves to the other side of its pin: it slides, never overshooting.
	var target:=Vector2(-90,10)
	var previous_distance:=INF
	var frames:=0
	while Fade.advance(fades,{"a":_card("a",anchor,target)},1.0/60.0) and frames<120:
		var drawn:=Fade.drawn_rect(fades,"a",Rect2(anchor+target,Vector2(80,24)),anchor)
		var distance:=drawn.position.distance_to(anchor+target)
		assert_float(distance).is_less_equal(previous_distance+0.001)
		previous_distance=distance
		frames+=1
	assert_int(frames).is_less(40)

func test_panning_moves_cards_with_their_pins_without_lag()->void:
	var fades:={}
	var offset:=Vector2(10,-30)
	for i in 30:Fade.advance(fades,{"a":_card("a",Vector2(100,100),offset)},1.0/60.0)
	# The camera pans: the pin and card move together; the drawn card follows at once.
	var anchor:=Vector2(160,90)
	var moving:=Fade.advance(fades,{"a":_card("a",anchor,offset)},1.0/60.0)
	assert_bool(moving).is_false()
	assert_vector(Fade.drawn_rect(fades,"a",Rect2(anchor+offset,Vector2(80,24)),anchor).position).is_equal(anchor+offset)

func test_reduced_motion_cuts_instead_of_fading()->void:
	Motion.reduce_motion=true
	var fades:={}
	var present:={"a":_card("a",Vector2(100,100),Vector2(10,-30))}
	assert_bool(Fade.advance(fades,present,1.0/60.0)).is_false()
	assert_float(Fade.alpha(fades,"a")).is_equal(1.0)
	Fade.advance(fades,{},1.0/60.0)
	assert_bool(fades.is_empty()).is_true()
