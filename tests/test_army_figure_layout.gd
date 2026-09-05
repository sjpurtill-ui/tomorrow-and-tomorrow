extends GdUnitTestSuite

@warning_ignore("unused_parameter")
func test_siege_heavy_force_keeps_bounded_proportions(do_skip:bool=DisplayServer.get_name()=="headless",skip_reason:String="Requires a real renderer for MultiMesh transform readback")->void:
	var formation:ArmyFigureFormation=auto_free(ArmyFigureFormation.new())
	formation.configure({"counterweight_trebuchet":1000000000},Color.WHITE)
	assert_int(formation.figure_count).is_equal(256)
	var batch:MultiMeshInstance3D=formation.batches.counterweight_trebuchet
	var low:=Vector3(INF,0,INF); var high:=Vector3(-INF,0,-INF)
	for i in batch.multimesh.instance_count:
		var point:=batch.multimesh.get_instance_transform(i).origin
		low.x=minf(low.x,point.x); low.z=minf(low.z,point.z)
		high.x=maxf(high.x,point.x); high.z=maxf(high.z,point.z)
	assert_float(high.x-low.x).is_greater(0.0)
	assert_float(high.z-low.z).is_less_equal((high.x-low.x)*2.0)

@warning_ignore("unused_parameter")
func test_budget_change_rebuilds_without_spreading_infantry(do_skip:bool=DisplayServer.get_name()=="headless",skip_reason:String="Requires a real renderer for MultiMesh transform readback")->void:
	var formation:ArmyFigureFormation=auto_free(ArmyFigureFormation.new())
	var counts:={"line_infantry":10000,"counterweight_trebuchet":2000}
	formation.figure_limit=64; formation.configure(counts,Color.WHITE)
	assert_int(formation.figure_count).is_equal(64)
	var infantry:MultiMeshInstance3D=formation.batches.line_infantry
	var first:=infantry.multimesh.get_instance_transform(0).origin
	var second:=infantry.multimesh.get_instance_transform(1).origin
	assert_float(first.distance_to(second)).is_equal_approx(1.25,0.0001)
	formation.figure_limit=32; formation.configure(counts,Color.WHITE)
	assert_int(formation.figure_count).is_equal(32)
	var total:=0
	for batch:MultiMeshInstance3D in formation.batches.values(): total+=batch.multimesh.instance_count
	assert_int(total).is_equal(32)
