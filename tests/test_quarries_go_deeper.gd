class_name QuarriesGoDeeperTest
extends GdUnitTestSuite
## Quarries and clay pits go deeper once a people knows how (resource_system.gd
## _deepen), and the town's repair mends with whatever building material it
## has (settlement_model.gd REPAIR_STANDINS).

var _known:Array

func before_test()->void:
	_known=GameState.known_discoveries.duplicate()

func after_test()->void:
	GameState.known_discoveries.clear(); GameState.known_discoveries.append_array(_known)

func _face(resource:="Stone")->Dictionary:
	return {"id":"t_face","resource":resource,"stage":"developed","remaining":0.0,"initial_amount":1000.0,"stock_at_source":0.0,"shipments":[],"in_transit":0.0}

func test_a_worked_out_face_opens_its_next_layer_when_the_people_know_quarrying()->void:
	GameState.known_discoveries.erase("quarry_reading")
	var face:=_face()
	ResourceSystem._deeper_day=-1
	ResourceSystem._deepen(face)
	assert_float(float(face.remaining)).is_equal(0.0)
	GameState.known_discoveries.append("quarry_reading")
	ResourceSystem._deeper_day=-1
	ResourceSystem._deepen(face)
	assert_float(float(face.remaining)).is_equal(1000.0)
	assert_int(int(face.depth)).is_equal(1)
	assert_float(ResourceSystem.depth_yield(face)).is_equal_approx(0.88,0.0001)
	face["depth"]=40
	assert_float(ResourceSystem.depth_yield(face)).is_equal(ResourceSystem.DEPTH_FLOOR)

func test_a_spent_face_is_not_spent_once_it_can_go_deeper()->void:
	GameState.known_discoveries.append("clay_shaping")
	ResourceSystem._deeper_day=-1
	var pit:=_face("Clay")
	ResourceSystem._mark_spent(pit)
	assert_bool(pit.has("spent")).is_false()
	var wood:=_face("Copper Ore")
	ResourceSystem._mark_spent(wood)
	assert_bool(bool(wood.get("spent",false))).is_true()

func test_a_face_with_a_working_reserve_is_left_alone()->void:
	GameState.known_discoveries.append("quarry_reading")
	ResourceSystem._deeper_day=-1
	var face:=_face()
	face.remaining=400.0
	ResourceSystem._deepen(face)
	assert_float(float(face.remaining)).is_equal(400.0)
	assert_bool(face.has("depth")).is_false()

func test_repair_mends_in_timber_and_clay_when_there_is_no_stone()->void:
	var stocks:Dictionary=GameState.resource_stockpiles
	var kept:=stocks.duplicate()
	var form:Dictionary=SettlementModel.city_form()
	var kept_form:=form.duplicate()
	form.tier=5.0; form.condition=0.5
	for item in ["Stone","Limestone","Clay"]: stocks[item]=0.0
	stocks["Timber"]=1_000_000.0
	SettlementModel._advance_city_form(0)
	assert_float(float(form.materials_paid)).is_equal(1.0)
	stocks["Timber"]=0.0
	SettlementModel._advance_city_form(0)
	assert_float(float(form.materials_paid)).is_equal(0.0)
	stocks.clear(); stocks.merge(kept)
	form.clear(); form.merge(kept_form)
