extends GdUnitTestSuite
## Mitred territory bands: offsets go the right way on either winding, inward
## offsets cannot fold a tiny territory, and repeated builds reuse heights.
const Band=preload("res://scripts/territory_border_band.gd")
const Samples=preload("res://scripts/settlement_surface_samples.gd")

func _circle(radius:float,clockwise:bool)->PackedVector2Array:
	var out:=PackedVector2Array()
	for i in 32:
		var angle:=TAU*i/32.0*(-1.0 if clockwise else 1.0)
		out.append(Vector2.from_angle(angle)*radius*(1.0+sin(i*1.7)*0.08)+Vector2(40,-12))
	return out

func _mean_radius(points:PackedVector2Array)->float:
	var total:=0.0
	for p in points: total+=p.distance_to(Vector2(40,-12))
	return total/points.size()

func test_offset_moves_outward_and_inward_on_both_windings()->void:
	for clockwise in [false,true]:
		var ring:=_circle(3.0,clockwise)
		assert_float(_mean_radius(Band.offset(ring,0.2))).is_greater(_mean_radius(ring)+0.15)
		assert_float(_mean_radius(Band.offset(ring,-0.2))).is_less(_mean_radius(ring)-0.15)

func test_inward_offset_never_crosses_the_centre()->void:
	var ring:=_circle(0.05,false)
	var inset:=Band.offset(ring,-5.0)
	for i in ring.size():
		assert_float(inset[i].distance_to(Vector2(40,-12))).is_greater_equal(ring[i].distance_to(Vector2(40,-12))*0.45)

func test_band_is_one_quad_per_piece_and_reuses_heights()->void:
	var calls:=[0]
	var samples:=Samples.new(func(x:float,z:float)->float:
		calls[0]+=1;return sin(x)*0.1+cos(z)*0.1,func(_p:Vector2)->bool:return true)
	var ring:=_circle(3.0,false)
	var inner:=Band.offset(ring,-0.3)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	assert_int(Band.append(surface,Band.offset(ring,0.01),Band.offset(ring,-0.01),ring,ring,Color.BLACK,Color.BLACK,0.006,samples,4)).is_equal(32)
	var arrays:=surface.commit_to_arrays()
	assert_int((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()).is_equal(32*4*6)
	var first:int=calls[0]
	# The hairline's heights come from the boundary itself: a second build at
	# another width costs no new height evaluations.
	surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	Band.append(surface,Band.offset(ring,0.05),Band.offset(ring,-0.05),ring,ring,Color.BLACK,Color.BLACK,0.006,samples,4)
	assert_int(calls[0]).is_equal(first)
	# The wash fades from its outer colour to a transparent inner edge.
	surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	Band.append(surface,ring,inner,ring,inner,Color(1,0.5,0,0.2),Color(1,0.5,0,0.0),0.0045,samples,4)
	var colors:=surface.commit_to_arrays()[Mesh.ARRAY_COLOR] as PackedColorArray
	var alphas:={}
	for c in colors: alphas[snappedf(c.a,0.01)]=true
	assert_bool(alphas.has(0.2) and alphas.has(0.0)).is_true()
