extends GdUnitTestSuite
## The army's makeup: shares stay whole and sane, every unit has its kind,
## and a garrison facing a border drawn in several pieces is counted once.
const Makeup:=preload("res://scripts/army_makeup.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Model:=preload("res://scripts/war_front_model.gd")


class FakeMilitary extends RefCounted:
	var army_makeup:={}


static func _sum(shares:Dictionary)->float:
	var total:=0.0
	for id in shares:total+=float(shares[id])
	return total


func test_clean_keeps_known_kinds_and_adds_to_one()->void:
	var cleaned:=Makeup.clean({"line":2.0,"missile":1.0,"cannons":5.0,"mounted":-1.0})
	assert_array(cleaned.keys()).contains_exactly_in_any_order(["line","missile"])
	assert_float(_sum(cleaned)).is_equal_approx(1.0,0.0001)
	assert_dict(Makeup.clean("junk")).is_empty()
	assert_dict(Makeup.clean({"line":0.0})).is_empty()


func test_unset_makeup_is_all_line()->void:
	var mc:=FakeMilitary.new()
	assert_bool(Makeup.chosen(mc)).is_false()
	assert_float(float(Makeup.shares(mc).line)).is_equal(1.0)


func test_raising_a_kind_takes_from_the_others_in_proportion()->void:
	var mc:=FakeMilitary.new()
	assert_bool(Makeup.step(mc,"missile",1).has("ok")).is_true()
	var shares:=Makeup.shares(mc)
	assert_float(float(shares.missile)).is_equal_approx(0.1,0.0001)
	assert_float(float(shares.line)).is_equal_approx(0.9,0.0001)
	Makeup.set_share(mc,"mounted",0.3)
	shares=Makeup.shares(mc)
	assert_float(float(shares.mounted)).is_equal_approx(0.3,0.0001)
	# Line and missile keep their 9:1 between them.
	assert_float(float(shares.line)/float(shares.missile)).is_equal_approx(9.0,0.01)
	assert_float(_sum(shares)).is_equal_approx(1.0,0.0001)


func test_line_cannot_drop_with_nothing_to_take_its_place()->void:
	var mc:=FakeMilitary.new()
	assert_bool(Makeup.step(mc,"line",-1).has("error")).is_true()
	assert_bool(Makeup.step(mc,"guns",-1).has("ok")).is_true()
	assert_float(float(Makeup.shares(mc).line)).is_equal(1.0)


func test_every_fighting_unit_has_a_kind()->void:
	assert_str(Makeup.role_of("levy")).is_equal("line")
	assert_str(Makeup.role_of("archer")).is_equal("missile")
	assert_str(Makeup.role_of("war_elephant")).is_equal("mounted")
	assert_str(Makeup.role_of("main_battle_tank")).is_equal("mounted")
	assert_str(Makeup.role_of("catapult_crew")).is_equal("guns")
	assert_str(Makeup.role_of("rifle_infantry")).is_equal("line")
	assert_str(Makeup.role_of("medical_detachment")).is_equal("")


func test_a_town_faces_only_the_border_piece_nearest_it()->void:
	var lines:=[PackedVector2Array([Vector2(0,0),Vector2(0,10)]),PackedVector2Array([Vector2(0,20),Vector2(0,30)]),PackedVector2Array([Vector2(0,40),Vector2(0,50)])]
	assert_int(Overlay._nearest_line(lines,Vector2(30,24))).is_equal(1)
	assert_int(Overlay._nearest_line(lines,Vector2(-5,2))).is_equal(0)
	# One town's garrison, sectored on the piece it faces, shows once.
	var theirs:=[{"at":Vector2(30,24),"men":13500,"known":true}]
	var ours:=[{"at":Vector2(-10,25),"name":"A","men":100}]
	var total:=0
	for i in lines.size():
		var facing:=theirs.filter(func(t:Dictionary)->bool:return Overlay._nearest_line(lines,t.at)==i)
		for sec:Dictionary in Model.border_sectors(lines[i],ours,facing,[],[]):total+=int(sec.theirs)
	assert_int(total).is_equal(13500)
