extends GdUnitTestSuite
## Shared exact terrain samples must not change a single map vertex.
const Samples=preload("res://scripts/settlement_surface_samples.gd")

class Terrain extends "res://scripts/local_terrain.gd":
	var height_calls:=0
	var land_calls:=0
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(x:float,z:float)->float:
		height_calls+=1;return sin(x*.37)*.21+cos(z*.53)*.13+x*.0011
	func _close_surface_height_at(x:float,z:float)->float:
		height_calls+=1;return sin(x*.41)*.17+cos(z*.29)*.19
	func _settlement_stage_land_at(point:Vector2)->bool:
		land_calls+=1;return point.x>-40.0

func _arrays(surface:SurfaceTool)->Array:
	return surface.commit_to_arrays()

func _surface()->SurfaceTool:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);return surface

func test_border_fill_and_ribbons_match_with_fewer_height_queries()->void:
	var terrain:Terrain=auto_free(Terrain.new())
	var boundary:=PackedVector2Array()
	for i in 32:boundary.append(Vector2.from_angle(TAU*i/32.0)*(3.0+sin(i*1.7)*.4)+Vector2(12,-5))
	var plain:Array=[];var shared:Array=[]
	terrain.height_calls=0
	var a:=_surface();var b:=_surface();var c:=_surface()
	terrain._append_settlement_claim_fill(a,boundary,Color.RED)
	terrain._append_settlement_boundary_ribbon(b,boundary,.08,Color.BLUE,.0045)
	terrain._append_settlement_boundary_ribbon(c,boundary,.03,Color.GREEN,.0065)
	plain=[_arrays(a),_arrays(b),_arrays(c)]
	var plain_calls:=terrain.height_calls
	terrain.height_calls=0
	var samples:=Samples.new(terrain._height_at,func(_p:Vector2)->bool:return true)
	a=_surface();b=_surface();c=_surface()
	terrain._append_settlement_claim_fill(a,boundary,Color.RED,.0032,samples)
	terrain._append_settlement_boundary_ribbon(b,boundary,.08,Color.BLUE,.0045,samples)
	terrain._append_settlement_boundary_ribbon(c,boundary,.03,Color.GREEN,.0065,samples)
	shared=[_arrays(a),_arrays(b),_arrays(c)]
	assert_bool(plain==shared).is_true()
	assert_int(terrain.height_calls).is_less(plain_calls/2)

func test_scout_corridor_ribbons_match_with_shared_samples()->void:
	var terrain:Terrain=auto_free(Terrain.new())
	var route:=PackedVector2Array([Vector2(-50,0),Vector2(-10,4),Vector2(20,-3),Vector2(45,11)])
	terrain.height_calls=0;terrain.land_calls=0
	var a:=_surface();var b:=_surface()
	terrain._append_settlement_system_ribbon(a,Vector3.ZERO,route,.9,Color.BLACK,.01,42)
	terrain._append_settlement_system_ribbon(b,Vector3.ZERO,route,.3,Color.YELLOW,.011,42)
	var plain:=[_arrays(a),_arrays(b)]
	var plain_calls:=terrain.height_calls+terrain.land_calls
	terrain.height_calls=0;terrain.land_calls=0
	var samples:=Samples.new(terrain._close_surface_height_at,terrain._settlement_stage_land_at)
	a=_surface();b=_surface()
	terrain._append_settlement_system_ribbon(a,Vector3.ZERO,route,.9,Color.BLACK,.01,42,0.0,0,samples)
	terrain._append_settlement_system_ribbon(b,Vector3.ZERO,route,.3,Color.YELLOW,.011,42,0.0,0,samples)
	assert_bool(plain==[_arrays(a),_arrays(b)]).is_true()
	assert_int(terrain.height_calls+terrain.land_calls).is_less(plain_calls)
