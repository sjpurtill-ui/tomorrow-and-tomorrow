extends GdUnitTestSuite
const DETAIL:=preload("res://scripts/woodland_harvest_detail.gd")
func _cover(_p:Vector2)->float: return 1.0
func _known(_p:Vector2)->bool: return true
func test_uncut_barren_and_hidden_ground_has_no_stumps()->void:
	var cut:=PackedVector4Array([Vector4(0,0,1.5,0)])
	assert_int(DETAIL.samples(Vector2.ZERO,PackedVector4Array(),42,_cover,_known).size()).is_equal(0)
	assert_int(DETAIL.samples(Vector2.ZERO,cut,42,func(_p:Vector2)->float:return 0.0,_known).size()).is_equal(0)
	assert_int(DETAIL.samples(Vector2.ZERO,cut,42,_cover,func(_p:Vector2)->bool:return false).size()).is_equal(0)
	assert_int(DETAIL.samples(Vector2(10,10),cut,42,_cover,_known).size()).is_equal(0)
func test_regrowth_removes_representatives_without_moving_survivors()->void:
	var cut:=DETAIL.samples(Vector2.ZERO,PackedVector4Array([Vector4(0,0,1.5,0)]),42,_cover,_known)
	var regrown:=DETAIL.samples(Vector2.ZERO,PackedVector4Array([Vector4(0,0,1.5,0.7)]),42,_cover,_known)
	assert_int(cut.size()).is_between(1,DETAIL.MAX_INSTANCES)
	assert_int(regrown.size()).is_between(1,cut.size()-1)
	for point in regrown: assert_bool(cut.has(point)).is_true()
func test_panning_preserves_world_positions_in_overlap()->void:
	var areas:=PackedVector4Array([Vector4(0,0,1.5,0)])
	var first:=DETAIL.samples(Vector2.ZERO,areas,42,_cover,_known)
	var next:=DETAIL.samples(Vector2(DETAIL.CELL,0),areas,42,_cover,_known)
	var overlap:=0
	for point in first:
		if next.has(point): overlap+=1
	assert_int(overlap).is_equal(110)

func test_aerial_view_hides_detail_and_returning_close_rebuilds()->void:
	var detail:MultiMeshInstance3D=auto_free(DETAIL.new())
	var cut:=PackedVector4Array([Vector4(0,0,1.5,0)])
	var ground:=func(_p:Vector2)->float: return 1.0
	detail.refresh(Vector2.ZERO,0.06,cut,42,1,_cover,_known,ground)
	assert_bool(detail.visible).is_true()
	assert_int(detail.multimesh.instance_count).is_equal(121)
	detail.refresh(Vector2.ZERO,5.0,cut,42,1,_cover,_known,ground)
	assert_bool(detail.visible).is_false()
	detail.refresh(Vector2.ZERO,0.06,cut,42,1,func(_p:Vector2)->float:return 0.0,_known,ground)
	assert_int(detail.multimesh.instance_count).is_equal(0)
