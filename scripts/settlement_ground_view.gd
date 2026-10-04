extends RefCounted
## Camera coverage only. The ground owner keeps its four frontier layers and
## retained high-resolution founding square; no world or settlement state changes.
const BASE_SIDE_KM:=0.512
const BASE_PAD_KM:=0.032
const MAX_VIEW_SPAN_KM:=40075.0

## World-XZ rectangle on the target-height plane, using the same ray projection
## as local_terrain._patch_covers_camera. The 0.46 half-span allowance adds a
## conservative relief margin. Invalid/horizon-facing views use bounded coverage.
static func camera_rect(camera:Camera3D,target:Vector3)->Rect2:
	var fallback:=_fallback_rect(camera,target)
	if camera==null or not camera.is_inside_tree() or not target.is_finite():return fallback
	var size:=camera.get_viewport().get_visible_rect().size
	if size.x<=0.0 or size.y<=0.0:return fallback
	var bounds:=Rect2(Vector2(target.x,target.z),Vector2.ZERO)
	for corner:Vector2 in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
		var direction:=camera.project_ray_normal(corner)
		var origin:=camera.project_ray_origin(corner)
		if not direction.is_finite() or not origin.is_finite() or direction.y>=-0.001:return fallback
		var distance:float=(target.y-origin.y)/direction.y
		if not is_finite(distance) or distance<0.0:return fallback
		var hit:=origin+direction*distance
		bounds=bounds.expand(Vector2(hit.x,hit.z))
	var span:=maxf(bounds.size.x,bounds.size.y)
	if not is_finite(span) or span>MAX_VIEW_SPAN_KM:return fallback
	return bounds.grow(maxf(BASE_PAD_KM,span*(1.0/0.92-1.0)*0.5))

static func _fallback_rect(camera:Camera3D,target:Vector3)->Rect2:
	var center:=Vector2(target.x,target.z) if target.is_finite() else Vector2.ZERO
	var span:=BASE_SIDE_KM
	if camera!=null:
		var aspect:=1.0
		if camera.is_inside_tree():
			var size:=camera.get_viewport().get_visible_rect().size
			if size.y>0.0:aspect=maxf(size.x/size.y,size.y/maxf(1.0,size.x))
		# Fourfold tilt allowance prevents an almost horizontal ray from asking
		# for infinite ground. Valid oblique cameras use their exact rays above.
		if is_finite(camera.size):span=clampf(camera.size*maxf(2.9,aspect*1.6)*4.0,BASE_SIDE_KM,MAX_VIEW_SPAN_KM)
	return Rect2(center-Vector2.ONE*span*0.5,Vector2.ONE*span)

## The caller supplies a settlement-local rectangle. Each dimension is at most
## one tile side, so its lower grid cell and the three neighbours always cover
## it. Padding is not part of this proof; it only supplies filtering overlap.
static func tile_layout(rect:Rect2)->Dictionary:
	var view:=rect.abs()
	if not view.position.is_finite() or not view.size.is_finite():view=Rect2(Vector2.ZERO,Vector2.ONE*BASE_SIDE_KM)
	var required:=maxf(view.size.x,view.size.y)
	# Match Vector2's precision at exact authored scale thresholds. Doubling
	# preserves the lattice without log-rounding into the next level by mistake.
	var side:float=Vector2(BASE_SIDE_KM,0.0).x
	var level:=0
	while side<required:
		side*=2.0;level+=1
	return {"level":level,"cell":Vector2i(floori(view.position.x/side),floori(view.position.y/side)),"side":side,"pad":side/16.0}
