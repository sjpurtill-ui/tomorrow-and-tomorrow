extends GdUnitTestSuite
## Default battle signs stay on the contact and leave troop detail to focus.
const Marks:=preload("res://scripts/hud/battle_marks.gd")


func test_signal_is_contact_centred_and_smaller_than_the_detail_plate()->void:
	var at:=Vector2(427,319)
	for scale in [0.8,1.0,1.25]:
		var rect:=Marks.signal_rect(at,scale)
		assert_vector(rect.get_center()).is_equal(at)
		assert_vector(rect.size).is_equal(Vector2(26,24)*scale)
		assert_float(rect.get_area()).is_less(Marks.plate_rect(at,scale).get_area()*0.2)


func test_single_and_cluster_signals_draw_with_their_declared_footprints()->void:
	var canvas:Control=auto_free(Control.new())
	add_child(canvas)
	var battle:={"progress":1.0,"age_days":0,"sides":{"a":{"colour":Color("4794b0"),"troops":1000000},"b":{"colour":Color("a34435"),"troops":2000000}}}
	var group:={"members":[{"battle":battle},{"battle":battle}],"progress":-1.0}
	var at:=Vector2(100,100)
	var drawn:={}
	canvas.draw.connect(func()->void:
		drawn.single=Marks.draw_signal(canvas,at,battle)
		drawn.cluster=Marks.draw_cluster_signal(canvas,at+Vector2(60,0),group)
	)
	canvas.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	assert_that(drawn.single).is_equal(Marks.signal_rect(at))
	assert_that(drawn.cluster).is_equal(Marks.cluster_signal_rect(at+Vector2(60,0),group))
	assert_vector((drawn.cluster as Rect2).size).is_equal(Vector2(32,32))
	# A one-battle cluster does not add a count badge or a larger hit region.
	group.members.resize(1)
	assert_that(Marks.cluster_signal_rect(at,group)).is_equal(Marks.signal_rect(at))
	group.members.clear()
	assert_bool(Marks.cluster_signal_rect(at,group).has_area()).is_false()
