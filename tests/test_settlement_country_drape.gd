extends GdUnitTestSuite
const Drape:=preload("res://scripts/settlement_country_drape.gd")
const Surface:=preload("res://scripts/rendered_surface_height.gd")

func _height(cell:Vector2i)->float:
	return sin(float(cell.x)*1.7)+cos(float(cell.y)*0.9)+float(cell.x*cell.y)*0.13

func _cross(a:Vector2,b:Vector2)->float:
	return float(a.x)*float(b.y)-float(a.y)*float(b.x)

func _area(triangle:Array)->float:
	return absf(_cross(triangle[1].point-triangle[0].point,triangle[2].point-triangle[0].point))*0.5

func _expected_color(point:Vector2,a:Vector2,b:Vector2,c:Vector2,ca:Color,cb:Color,cc:Color)->Color:
	var denominator:=_cross(b-a,c-a)
	var toward_b:=_cross(point-a,c-a)/denominator
	var toward_c:=_cross(b-a,point-a)/denominator
	return ca*(1.0-toward_b-toward_c)+cb*toward_b+cc*toward_c

func _assert_color(actual:Color,expected:Color)->void:
	for component in 4:assert_float(actual[component]).is_equal_approx(expected[component],0.000005)

func test_each_piece_has_affine_height_on_the_actual_alternating_mesh()->void:
	var grid:=Vector4(0,0,4,5)
	var a:=Vector2(-1.7,-1.6);var b:=Vector2(1.8,-0.8);var c:=Vector2(-0.2,1.7)
	var triangles:=Drape.split_triangle(a,b,c,Color.RED,Color.GREEN,Color.BLUE,grid)
	assert_int(triangles.size()).is_greater(12)
	assert_bool(Drape.contains_all(a,b,c,grid)).is_true()
	for triangle:Array in triangles:
		assert_int(triangle.size()).is_equal(3)
		var h0:=Surface.sample(triangle[0].point,grid,_height)
		var h1:=Surface.sample(triangle[1].point,grid,_height)
		var h2:=Surface.sample(triangle[2].point,grid,_height)
		for weights:Vector3 in [Vector3.ONE/3.0,Vector3(0.19,0.27,0.54),Vector3(0.71,0.17,0.12)]:
			var point:Vector2=triangle[0].point*weights.x+triangle[1].point*weights.y+triangle[2].point*weights.z
			assert_float(Surface.sample(point,grid,_height)).is_equal_approx(h0*weights.x+h1*weights.y+h2*weights.z,0.000005)
		var center:Vector2=(triangle[0].point+triangle[1].point+triangle[2].point)/3.0+Vector2(2,2)
		var cell:=Vector2i(floori(center.x),floori(center.y))
		var fraction:=center-Vector2(cell)
		for vertex:Dictionary in triangle:
			var local:Vector2=vertex.point+Vector2(2,2)-Vector2(cell)
			assert_float(local.x).is_between(-0.00001,1.00001)
			assert_float(local.y).is_between(-0.00001,1.00001)
			if (cell.x+cell.y)%2==0:
				assert_float((local.x-local.y)*(1.0 if fraction.x>=fraction.y else -1.0)).is_greater_equal(-0.00001)
			else:
				assert_float((local.x+local.y-1.0)*(1.0 if fraction.x+fraction.y>=1.0 else -1.0)).is_greater_equal(-0.00001)

func test_clipping_preserves_rgba_and_exact_intersection_area()->void:
	var a:=Vector2(-2,-2);var b:=Vector2(2,-2);var c:=Vector2(0,2)
	var ca:=Color(0.1,0.2,0.3,0.4);var cb:=Color(0.8,0.4,0.1,0.7);var cc:=Color(0.3,0.9,0.6,1.0)
	var grid:=Vector4(0,0,2,3)
	var status:=Drape.triangle_status(a,b,c,grid)
	assert_str(status.status).is_equal("clipped")
	assert_bool(Drape.contains_all(a,b,c,grid)).is_false()
	assert_int(status.cell_count).is_equal(4)
	var triangles:=Drape.split_triangle(a,b,c,ca,cb,cc,grid)
	var area:=0.0
	for triangle:Array in triangles:
		area+=_area(triangle)
		for vertex:Dictionary in triangle:
			assert_bool(Surface.contains(vertex.point,grid)).is_true()
			_assert_color(vertex.color,_expected_color(vertex.point,a,b,c,ca,cb,cc))
	assert_float(area).is_equal_approx(3.5,0.00001)

func test_even_and_odd_cells_use_opposite_diagonals()->void:
	var grid:=Vector4(0,0,2,3)
	for points:Array in [[Vector2(-0.9,-0.9),Vector2(-0.1,-0.9),Vector2(-0.9,-0.1)],
		[Vector2(0.1,-0.9),Vector2(0.9,-0.9),Vector2(0.9,-0.1)]]:
		var triangles:=Drape.split_triangle(points[0],points[1],points[2],Color.RED,Color.GREEN,Color.BLUE,grid)
		assert_int(triangles.size()).is_equal(2)
		var total:=0.0
		for triangle:Array in triangles:total+=_area(triangle)
		assert_float(total).is_equal_approx(0.32,0.000001)

func test_existing_facet_and_clockwise_input_are_not_duplicated()->void:
	var grid:=Vector4(0,0,2,2)
	var a:=Vector2(-1,-1);var b:=Vector2(1,-1);var c:=Vector2(1,1)
	var forward:=Drape.split_triangle(a,b,c,Color.RED,Color.GREEN,Color.BLUE,grid)
	var backward:=Drape.split_triangle(c,b,a,Color.BLUE,Color.GREEN,Color.RED,grid)
	assert_int(forward.size()).is_equal(1)
	assert_int(backward.size()).is_equal(1)
	assert_float(_area(forward[0])).is_equal(2.0)
	assert_float(_area(backward[0])).is_equal(2.0)
	assert_array(Drape.split_triangle(a,b,c,Color.RED,Color.GREEN,Color.BLUE,grid)).is_equal(forward)
	for vertex:Dictionary in backward[0]:_assert_color(vertex.color,_expected_color(vertex.point,a,b,c,Color.RED,Color.GREEN,Color.BLUE))

func test_cell_and_output_work_are_hard_bounded()->void:
	# The clipped source covers the whole eight-by-eight-cell grid.
	var grid:=Vector4(0,0,8,9)
	var a:=Vector2(-8,-8);var b:=Vector2(16,-8);var c:=Vector2(-8,16)
	assert_int(Drape.triangle_status(a,b,c,grid).cell_count).is_equal(Drape.MAX_CELLS)
	var triangles:=Drape.split_triangle(a,b,c,Color.WHITE,Color.WHITE,Color.WHITE,grid)
	assert_int(triangles.size()).is_between(1,Drape.MAX_OUTPUT_TRIANGLES)
	var area:=0.0
	for triangle:Array in triangles:area+=_area(triangle)
	assert_float(area).is_equal_approx(64.0,0.00001)
	grid=Vector4(0,0,128,129);a=Vector2(-64,-64);b=Vector2(64,-64);c=Vector2(-64,64)
	assert_bool(Drape.contains_all(a,b,c,grid)).is_true()
	assert_str(Drape.triangle_status(a,b,c,grid).status).is_equal("budget_exceeded")
	assert_int(Drape.split_triangle(a,b,c,Color.WHITE,Color.WHITE,Color.WHITE,grid).size()).is_equal(0)
	grid=Vector4(0,0,256,257);a=Vector2(-127,-127);b=Vector2(127,127);c=Vector2(127,126.9)
	var row_limit:=Drape.triangle_status(a,b,c,grid)
	assert_str(row_limit.status).is_equal("budget_exceeded")
	assert_int(row_limit.rows_scanned).is_less_equal(Drape.MAX_ROWS)

func test_thin_diagonal_strips_count_only_the_cells_they_cross()->void:
	var grid:=Vector4(0,0,20,21)
	var a:=Vector2(-9.5,-9.48);var b:=Vector2(9.5,9.52);var c:=Vector2(9.5,9.48)
	var status:=Drape.triangle_status(a,b,c,grid)
	var box_cells:int=(status.cell_max.x-status.cell_min.x+1)*(status.cell_max.y-status.cell_min.y+1)
	assert_int(box_cells).is_greater(Drape.MAX_CELLS)
	assert_str(status.status).is_equal("inside")
	assert_int(status.cell_count).is_between(20,Drape.MAX_CELLS)
	assert_int(status.rows_scanned).is_less_equal(Drape.MAX_ROWS)
	var span_cells:=0
	for span:Vector3i in status.row_spans:span_cells+=span.z-span.y+1
	assert_int(span_cells).is_equal(status.cell_count)
	var triangles:=Drape.split_triangle(a,b,c,Color.RED,Color.GREEN,Color.BLUE,grid)
	assert_int(triangles.size()).is_between(20,Drape.MAX_OUTPUT_TRIANGLES)
	var area:=0.0
	var max_color_error:=0.0
	for triangle:Array in triangles:
		area+=_area(triangle)
		for vertex:Dictionary in triangle:
			var expected:=_expected_color(vertex.point,a,b,c,Color.RED,Color.GREEN,Color.BLUE)
			for component in 4:max_color_error=maxf(max_color_error,absf(vertex.color[component]-expected[component]))
	assert_float(area).is_equal_approx(absf(_cross(b-a,c-a))*0.5,0.00003)
	# Reconstructing barycentric colors from float32 world points amplifies
	# rounding at this 475:1 aspect ratio. The broad-triangle test retains its
	# tighter 5e-6 tolerance; this strip still requires <0.01% channel error.
	assert_float(max_color_error).is_less_equal(0.0001)
	print("COUNTRY_DRAPE_THIN_STRIP BBOX_CELLS=%d VISITED_CELLS=%d PIECES=%d MAX_COLOR_ERROR=%.8f" % [box_cells,status.cell_count,triangles.size(),max_color_error])

func test_off_grid_extent_is_clipped_before_the_cell_budget_is_counted()->void:
	var grid:=Vector4(0,0,2,9)
	var a:=Vector2(-100,-0.2);var b:=Vector2(0.2,-0.2);var c:=Vector2(0.2,0.2)
	var status:=Drape.triangle_status(a,b,c,grid)
	assert_str(status.status).is_equal("clipped")
	assert_int(status.cell_count).is_less_equal(Drape.MAX_CELLS)
	assert_int(Drape.split_triangle(a,b,c,Color.WHITE,Color.WHITE,Color.WHITE,grid).size()).is_greater(0)

func test_outside_invalid_and_degenerate_inputs_return_no_geometry()->void:
	var grid:=Vector4(0,0,2,3)
	var a:=Vector2(10,10);var b:=Vector2(11,10);var c:=Vector2(10,11)
	assert_str(Drape.triangle_status(a,b,c,grid).status).is_equal("outside")
	assert_int(Drape.split_triangle(a,b,c,Color.WHITE,Color.WHITE,Color.WHITE,grid).size()).is_equal(0)
	for bad_grid:Vector4 in [Vector4.ZERO,Vector4(0,0,2,1),Vector4(INF,0,2,3)]:
		assert_str(Drape.triangle_status(Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,bad_grid).status).is_equal("invalid")
		assert_int(Drape.split_triangle(Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN,Color.WHITE,Color.WHITE,Color.WHITE,bad_grid).size()).is_equal(0)
	assert_str(Drape.triangle_status(Vector2.ZERO,Vector2.RIGHT,Vector2(2,0),grid).status).is_equal("invalid")
	assert_str(Drape.triangle_status(Vector2.INF,Vector2.RIGHT,Vector2.DOWN,grid).status).is_equal("invalid")

func test_planetary_grid_keeps_affine_heights_within_twenty_centimetres()->void:
	var origin:=Vector2(14034,-2900)
	var grid:=Vector4(origin.x,origin.y,12.0,129.0)
	var spacing:=grid.z/float(int(grid.w)-1)
	var height:=func(cell:Vector2i)->float:
		return 0.853+sin(float(cell.x)*1.73+float(cell.y)*0.31)*0.01+cos(float(cell.y)*0.87)*0.007
	var cases:Array=[
		[Vector2(-0.171,-0.142),Vector2(0.153,-0.064),Vector2(-0.063,0.187)],
		[Vector2(5.81,5.84),Vector2(6.04,5.91),Vector2(5.85,6.12)],
		[Vector2(-6.02,-0.122),Vector2(-5.71,-0.202),Vector2(-5.78,0.178)],
		[Vector2(-0.28,-0.23),Vector2(0.24,0.29),Vector2(0.243,0.287)]]
	var max_error:=0.0
	var max_facet_drift:=0.0
	var piece_count:=0
	for offsets:Array in cases:
		var a:Vector2=origin+offsets[0];var b:Vector2=origin+offsets[1];var c:Vector2=origin+offsets[2]
		var triangles:=Drape.split_triangle(a,b,c,Color.RED,Color.GREEN,Color.BLUE,grid)
		assert_int(triangles.size()).is_greater(0)
		piece_count+=triangles.size()
		for triangle:Array in triangles:
			var p0:Vector2=triangle[0].point;var p1:Vector2=triangle[1].point;var p2:Vector2=triangle[2].point
			var h0:=Surface.sample(p0,grid,height);var h1:=Surface.sample(p1,grid,height);var h2:=Surface.sample(p2,grid,height)
			for vertex:Dictionary in triangle:assert_bool(Surface.contains(vertex.point,grid)).is_true()
			# Form the centroid relative to one vertex, avoiding an artificial
			# extra loss from summing three planetary coordinates in float32.
			var center:=p0+((p1-p0)+(p2-p0))/3.0
			for weights:Vector3 in [Vector3.ONE/3.0,Vector3(0.2,0.3,0.5),Vector3(0.7,0.2,0.1)]:
				var point:=p0+(p1-p0)*weights.y+(p2-p0)*weights.z
				var expected:=h0*weights.x+h1*weights.y+h2*weights.z
				max_error=maxf(max_error,absf(Surface.sample(point,grid,height)-expected))
			var at:Vector2=((center-origin)/grid.z+Vector2(0.5,0.5))*128.0
			var cell:=Vector2i(clampi(floori(at.x),0,127),clampi(floori(at.y),0,127))
			var fraction:=at-Vector2(cell)
			for vertex:Dictionary in triangle:
				var local:Vector2=((Vector2(vertex.point)-origin)/grid.z+Vector2(0.5,0.5))*128.0-Vector2(cell)
				var drift:=maxf(maxf(-local.x,local.x-1.0),maxf(-local.y,local.y-1.0))
				if (cell.x+cell.y)%2==0:
					drift=maxf(drift,-(local.x-local.y)*(1.0 if fraction.x>=fraction.y else -1.0)/sqrt(2.0))
				else:
					drift=maxf(drift,-(local.x+local.y-1.0)*(1.0 if fraction.x+fraction.y>=1.0 else -1.0)/sqrt(2.0))
				max_facet_drift=maxf(max_facet_drift,drift*spacing)
	# A Vector2 at this longitude has a 0.977m x-coordinate ULP. Boundary
	# drift may round within that ULP, but cannot move a piece into another
	# 93.75m grid cell/facet. Height error must remain under the requested20cm.
	print("COUNTRY_DRAPE_PLANET_PIECES=%d MAX_HEIGHT_ERROR_M=%.6f MAX_FACET_DRIFT_M=%.6f" % [piece_count,max_error*1000.0,max_facet_drift*1000.0])
	assert_float(max_error).is_less_equal(0.0002)
	assert_float(max_facet_drift).is_less_equal(0.001)
