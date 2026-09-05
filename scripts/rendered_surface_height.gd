extends RefCounted
## Interpolate actual mesh triangles, not the continuous generator beneath them.
static func contains(point:Vector2,grid:Vector4)->bool:
	return grid.z>0.0 and grid.w>=2.0 and maxf(absf(point.x-grid.x),absf(point.y-grid.y))<=grid.z*0.5

static func sample(point:Vector2,grid:Vector4,height:Callable,alternating:bool=true)->float:
	if not contains(point,grid): return NAN
	var resolution:=int(grid.w)
	var position:=((point-Vector2(grid.x,grid.y))/grid.z+Vector2(0.5,0.5))*float(resolution-1)
	var cell:=Vector2i(clampi(floori(position.x),0,resolution-2),clampi(floori(position.y),0,resolution-2))
	var fraction:=(position-Vector2(cell)).clamp(Vector2.ZERO,Vector2.ONE)
	var a:float=height.call(cell)
	var b:float=height.call(cell+Vector2i(1,0))
	var c:float=height.call(cell+Vector2i(1,1))
	var d:float=height.call(cell+Vector2i(0,1))
	if not alternating or (cell.x+cell.y)%2==0:
		return a+(b-a)*fraction.x+(c-b)*fraction.y if fraction.x>=fraction.y else a+(c-d)*fraction.x+(d-a)*fraction.y
	return a+(b-a)*fraction.x+(d-a)*fraction.y if fraction.x+fraction.y<=1.0 else c+(d-c)*(1.0-fraction.x)+(b-c)*(1.0-fraction.y)
