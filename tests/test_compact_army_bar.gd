extends GdUnitTestSuite

const Bar:=preload("res://scripts/hud/army_bar.gd")

class MapStub extends Node:
	var selected_army_id:=-1

class BarStub extends "res://scripts/hud/army_bar.gd":
	var fixture:Array[Dictionary]=[]
	var war:=false
	func refresh()->void:_apply_cards(fixture,war)

class CommandStub extends RefCounted:
	var data:={"nodes":{
		"one":{"id":"one","service":"army","force_id":1},
		"two":{"id":"two","service":"army","force_id":2},
		"three":{"id":"three","service":"army","force_id":3}}}
	func order_for(id:String)->Dictionary:
		return {"mission":"defend","zone_id":"west" if id in ["one","two"] else "east"}

var bar:Control
var map:Node

func _card(id:int)->Dictionary:
	return {"id":"army:%d" % id,"kind":"army","army_id":id,"members":[id],"title":"Band %d" % id,"short":"Band %d" % id,"men":100,
		"gear":1.0,"will":0.8,"fed":1.0,"general":{},"position":Vector2.INF}

func before_test()->void:
	map=MapStub.new();add_child(map)
	bar=BarStub.new();bar.terrain=map;bar.fixture.assign([_card(1),_card(2)]);add_child(bar)
	bar.set_process(false);bar.place(Rect2(10,10,500,bar.bar_height()))

func after_test()->void:
	# Rebuilding removes old cards before queue_free; let their deferred
	# disposal finish before GdUnit checks the live fixture's ownership.
	await get_tree().process_frame
	bar.free();map.free()

func test_idle_disclosure_opens_existing_cards_and_collapses_without_a_lingering_selection()->void:
	assert_bool(bar.expanded()).is_false()
	assert_float(bar.bar_height()).is_equal(30.0)
	assert_float(bar.disclosure.size.y).is_equal(30.0)
	assert_str(bar.disclosure.text).contains("Armies · 2")
	assert_int(bar.strip.get_child_count()).is_equal(0)
	bar.toggle_disclosure();bar.place(Rect2(10,10,500,bar.bar_height()))
	assert_bool(bar.expanded()).is_true()
	assert_int(bar.strip.get_child_count()).is_equal(2)
	assert_bool(bar.strip.visible).is_true()
	bar.select_card(bar.fixture[0])
	assert_int(map.selected_army_id).is_equal(1)
	bar.toggle_disclosure()
	assert_bool(bar.expanded()).is_false()
	assert_str(bar.selected_id).is_empty()
	assert_int(map.selected_army_id).is_equal(-1)
	bar.refresh()
	assert_float(bar.bar_height()).is_equal(30.0)

func test_map_selection_opens_then_map_deselection_restores_the_quiet_default()->void:
	map.selected_army_id=2;bar.refresh()
	assert_bool(bar.expanded()).is_true()
	assert_str(bar.selected_id).is_equal("army:2")
	map.selected_army_id=-1;bar.refresh()
	assert_bool(bar.expanded()).is_false()
	assert_str(bar.selected_id).is_empty()
	# A destroyed/removed selected band cannot leave its details hanging open.
	map.selected_army_id=1;bar.refresh();bar.fixture.assign([_card(2)]);bar.refresh()
	assert_bool(bar.expanded()).is_false()

func test_war_opens_details_without_leaving_them_open_after_war_closes()->void:
	bar.war=true;bar.refresh()
	assert_bool(bar.expanded()).is_true()
	assert_int(bar.strip.get_child_count()).is_equal(2)
	assert_bool(bar.disclosure.disabled).is_true()
	bar.toggle_disclosure()
	assert_bool(bar.expanded()).is_true()
	bar.war=false;bar.refresh()
	assert_bool(bar.expanded()).is_false()
	assert_bool(bar.disclosure.disabled).is_false()

func test_count_and_plan_ink_follow_only_the_selected_band_or_general()->void:
	var first:=_card(1);var second:=_card(2)
	bar.fixture.assign([{"id":"general:fith","kind":"group","army_id":1,"members":[1,2],"member_cards":[first,second],
		"title":"Fith","short":"Fith","men":200,"general":{},"position":Vector2.INF},_card(3)])
	bar.refresh()
	assert_str(bar.disclosure.text).contains("Armies · 3")
	var command:=CommandStub.new()
	assert_array(bar.selected_plan_zones(command)).is_empty()
	bar.select_card(bar.fixture[0])
	assert_array(bar.selected_plan_zones(command)).is_equal(["west"])
	bar.select_card(bar.fixture[1])
	assert_array(bar.selected_plan_zones(command)).is_equal(["east"])
	bar.toggle_disclosure()
	assert_array(bar.selected_plan_zones(command)).is_empty()
	map.selected_army_id=2;bar.refresh()
	assert_str(bar.selected_id).is_equal("army:2")
	assert_array(bar.selected_plan_zones(command)).is_equal(["west"])

func test_eight_members_scroll_inside_the_available_bar_and_selected_last_band_is_reachable()->void:
	var member_cards:Array=[]
	for id in range(1,9):member_cards.append(_card(id))
	bar.fixture.assign([{"id":"general:eight","kind":"group","army_id":1,"members":[1,2,3,4,5,6,7,8],"member_cards":member_cards,
		"title":"Eight bands","short":"Eight bands","men":800,"general":{},"position":Vector2.INF}])
	bar.refresh();bar.select_card(bar.fixture[0])
	# The full 1152px view leaves 600px between map rail, orders and margins.
	bar.place(Rect2(120,450,600,bar.bar_height()))
	await get_tree().process_frame
	assert_int(bar.members.get_child_count()).is_equal(8)
	assert_float(bar.member_scroll.size.x).is_less_equal(600.0)
	assert_bool(bar.member_scroll.clip_contents).is_true()
	assert_bool(bar.member_scroll.get_h_scroll_bar().visible).is_true()
	assert_bool(bar.get_global_rect().encloses(bar.member_scroll.get_global_rect())).is_true()
	assert_float(bar.member_scroll.size.y).is_greater_equal(Bar.CHIP_SIZE.y+bar.member_scroll.get_h_scroll_bar().get_combined_minimum_size().y)
	bar.select_card(member_cards[7]);bar.place(Rect2(120,450,600,bar.bar_height()))
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(bar.selected_id).is_equal("army:8")
	assert_int(map.selected_army_id).is_equal(8)
	assert_int(bar.member_scroll.scroll_horizontal).is_greater(0)
	var last:Control=bar.members.get_child(7)
	assert_bool(bar.member_scroll.get_global_rect().encloses(last.get_global_rect())).is_true()
	bar.member_scroll.scroll_horizontal=0
	await get_tree().process_frame
	assert_bool(bar.member_scroll.get_global_rect().encloses(bar.members.get_child(0).get_global_rect())).is_true()
