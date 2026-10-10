extends GdUnitTestSuite
## Battle readouts leave their contact visible and clickable. Their complete
## paper footprints govern placement, counter clearance and pointer hits.
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Marks:=preload("res://scripts/hud/battle_marks.gd")
const Source:=preload("res://scripts/hud/battle_marker_source.gd")
const Counter:=preload("res://scripts/hud/army_counter.gd")


class FakeHud extends Control:
	var army_bar:Control
	var order_stack:Control
	var queue_root:Control
	var toolbar:Control
	var dock:Control
	var detail_dock:Control
	var army_alerts:Control


class FakeTerrain extends Node3D:
	var hud:Control
	var city_labels:Control
	var map_help_button:Control


static func _battle(id:String="fight")->Dictionary:
	return {"id":id,"kind":"battle","pos":Vector2.ZERO,"ours":true,"army_id":7,"status":"fighting","age_days":0,"progress":0.2,
		"label":"Border crossing · day 1","hover":"We are pushing them back",
		"sides":{"a":{"troops":20000},"b":{"troops":18000}}}


func test_readout_clears_contact_front_city_and_hud_in_a_small_window()->void:
	var bounds:=Rect2(90,100,940,530)
	var contact:=Vector2(520,355)
	var clear:Array[Rect2]=[Rect2(contact-Vector2(42,42),Vector2(84,84))]
	var blocked:Array[Rect2]=[Rect2(508,150,24,430),Rect2(590,280,220,120)]
	var rect:=Overlay.place_battle_plate(contact,Vector2(240,64),bounds,blocked,clear)
	assert_bool(bounds.encloses(rect)).is_true()
	for obstacle in blocked+clear:assert_bool(rect.intersects(obstacle)).is_false()
	assert_that(Overlay.place_battle_plate(contact,rect.size,bounds,blocked,clear)).is_equal(rect)
	# Camera-edge contacts still place wholly inside the usable chart.
	for anchor in [bounds.position,bounds.end,Vector2(bounds.end.x,bounds.position.y)]:
		var edge_clear:Array[Rect2]=[Rect2(anchor-Vector2(42,42),Vector2(84,84))]
		var edge:=Overlay.place_battle_plate(anchor,rect.size,bounds,[],edge_clear)
		assert_bool(bounds.encloses(edge)).is_true()
		assert_bool(edge.intersects(edge_clear[0])).is_false()


func test_a_long_plate_does_not_capture_the_empty_space_above_it()->void:
	var overlay:Control=auto_free(Overlay.new())
	var box:=Rect2(600,250,240,60)
	var hit:={"kind":"battle","rect":box,"centre":box.get_center(),"contact":Vector2(520,355),"contact_radius":11.0,"battle":_battle()}
	overlay.hits=[hit]
	assert_dict(overlay.battle_at(box.position+Vector2(1,1))).is_not_empty()
	assert_dict(overlay.battle_at(box.end-Vector2(1,1))).is_not_empty()
	assert_dict(overlay.battle_at(Vector2(520,355))).is_not_empty()
	assert_dict(overlay.battle_at(box.get_center()-Vector2(0,70))).is_empty()
	assert_dict(overlay.hit_at(box.get_center()-Vector2(0,70))).is_empty()
	# The old broad battle circle used to steal a nearby army's click.
	var army_rect:=Rect2(680,185,80,30)
	overlay.hits.append({"kind":"army","rect":army_rect,"centre":army_rect.get_center(),"army_id":9,"mark":true})
	assert_dict(overlay.battle_at(army_rect.get_center())).is_empty()
	assert_int(int(overlay.mark_at(army_rect.get_center()).army_id)).is_equal(9)
	assert_dict(overlay.mark_at(army_rect.get_center()+Vector2(0,25))).is_empty()


func test_the_cluster_uses_the_same_complete_bounds_for_drawing_and_hits()->void:
	var canvas:Control=auto_free(Control.new())
	add_child(canvas)
	var at:=Vector2(300,200)
	var group:={"members":[{"battle":_battle("one")},{"battle":_battle("two")}],"progress":0.1}
	var drawn:={"rect":Rect2()}
	canvas.draw.connect(func()->void:drawn.rect=Marks.draw_cluster(canvas,at,group,0,ThemeDB.fallback_font))
	canvas.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	var expected:=Marks.cluster_rect(at,group)
	assert_that(drawn.rect).is_equal(expected)
	assert_float(expected.size.x).is_less(Marks.plate_rect(at,0.9,_battle()).size.x)
	var hit:={"kind":"battles","rect":expected,"centre":expected.get_center()}
	assert_bool(Overlay._hit_contains(hit,expected.end-Vector2(1,1))).is_true()
	assert_bool(Overlay._hit_contains(hit,expected.get_center()+Vector2(0,expected.size.y))).is_false()


func test_contact_and_readout_both_open_the_same_battle_after_layout()->void:
	var overlay:Control=auto_free(Overlay.new())
	overlay.project=func(_p:Vector2)->Vector2:return Vector2(570,350)
	overlay.band_override="local"
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	overlay.size=Vector2(1152,720)
	overlay.set_scene({"battles":[_battle()],"era":0},true)
	overlay.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	var entry:Dictionary=overlay.battle_cache[0]
	assert_bool((entry.rect as Rect2).has_point(entry.contact_at)).is_false()
	assert_float((entry.at as Vector2).distance_to(entry.contact_at)).is_greater(50.0)
	var opened:Array=[]
	overlay.battle_opener=func(request:Dictionary)->void:opened.append(request)
	for point in [entry.contact_at,(entry.rect as Rect2).get_center()]:
		var hit:Dictionary=overlay.battle_at(point)
		assert_str(String(hit.battle.id)).is_equal("fight")
		overlay.open_battle(hit,point)
	assert_int(opened.size()).is_equal(2)
	assert_that(opened[0]).is_equal(opened[1])
	assert_array(opened[0].args).is_equal([7,-1])


func test_default_counter_captions_preserve_age_without_repeating_counts()->void:
	assert_str(Overlay.counter_caption({"side":"ours","troops":20000,"sector":true,"members":["one"]})).is_empty()
	assert_str(Overlay.counter_caption({"side":"theirs","low":9500,"high":30000,"age_days":0})).is_empty()
	assert_str(Overlay.counter_caption({"side":"theirs","age_days":18})).contains("seen 18 days ago")
	assert_str(Overlay.counter_caption({"side":"ours","report_age":18})).contains("reported 18 days ago")


func test_far_battle_readouts_stay_compact_even_for_large_armies()->void:
	var battle:=_battle()
	var local:=Marks.plate_rect(Vector2.ZERO,Overlay._mark_scale(battle,"local"),battle)
	var far:=Marks.plate_rect(Vector2.ZERO,Overlay._mark_scale(battle,"continental"),battle)
	assert_float(far.size.y).is_less(local.size.y*0.7)
	assert_float(far.size.x).is_less(local.size.x*0.7)


func test_actual_visible_hud_panels_are_reserved_for_plates_and_counters()->void:
	var terrain:Node3D=auto_free(FakeTerrain.new())
	var hud:Control=FakeHud.new()
	terrain.hud=hud
	add_child(terrain)
	terrain.add_child(hud)
	for key in ["army_bar","order_stack"]:
		var panel:=Control.new()
		hud.add_child(panel)
		panel.position=Vector2(320,550) if key=="army_bar" else Vector2(790,550)
		panel.size=Vector2(220,100)
		hud.set(key,panel)
	var overlay:Control=auto_free(Overlay.new())
	overlay.terrain=terrain
	overlay.size=Vector2(1152,720)
	var chart:Dictionary=overlay._chart_obstacles()
	assert_int((chart.rects as Array).size()).is_equal(2)
	overlay.counter_bounds=chart.bounds
	overlay.counter_fixed=chart.rects
	var extent:=Vector2(130,42)
	var spot:Vector2=overlay._counter_spot(Vector2(430,570),extent,1.0)
	var counter:=Rect2(spot-extent*0.5,extent)
	for obstacle in chart.rects:assert_bool(counter.intersects(obstacle)).is_false()
	# A hidden panel does not reserve dead space.
	hud.order_stack.hide()
	assert_int((overlay._chart_obstacles().rects as Array).size()).is_equal(1)


func test_our_battle_uses_hostile_red_when_enemy_identity_is_blue()->void:
	var context:={"today":100,"home":Vector2.ZERO,"armies":{7:Vector2(1,0)},"colours":{"rival":Source.OURS_COLOUR}}
	for side in ["attacker","defender"]:
		var engagement:={"home_side":side,"home_force_id":7,"attacker":{"troops":20000},"defender":{"troops":18000},
			"threat":{"source_civ_id":"rival","source_name":"Esurai"}}
		var battle:=Source.from_engagement(engagement,"fight",context)
		assert_that(battle.sides.a.colour).is_equal(Source.OURS_COLOUR)
		assert_that(battle.sides.b.colour).is_equal(Source.THEIRS_COLOUR)
		assert_bool(battle.sides.a.colour==battle.sides.b.colour).is_false()


func test_counter_clearance_contains_the_drawn_days_tab()->void:
	var canvas:Control=auto_free(Control.new())
	add_child(canvas)
	var data:={"side":"ours","troops":20000,"march_done":0.5,"days_left":18,"state":"marching","members":3}
	var at:=Vector2(300,200)
	var drawn:={"rect":Rect2()}
	canvas.draw.connect(func()->void:drawn.rect=Counter.draw(canvas,at,data,0.85))
	canvas.queue_redraw()
	await await_idle_frame()
	await await_idle_frame()
	var room:=Overlay.counter_clearance(data,0.85)
	room.position+=at
	assert_bool(room.encloses(drawn.rect)).is_true()
