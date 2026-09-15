extends RefCounted
## Rendering density only. Heights, climate and resources keep their authorities.
const MAX_SPAN_KM:=40075.0
const MAX_RESOLUTION:=513
const CACHE_VERTEX_BUDGET:=600000
const CACHE_ENTRY_LIMIT:=4

static func view_span(height_km:float,aspect:float,pitch:float)->float:
	# Covers rotation, oblique viewing and the snapped-center margin, including
	# wide windows. The coarse planet remains behind any unfinished coverage.
	var tilt:=1.0/clampf(sin(absf(pitch)),0.42,1.0)
	return clampf(height_km*maxf(2.9,aspect*1.6)*tilt,1.2,MAX_SPAN_KM)

static func bucket(span:float)->float:
	return clampf(pow(1.5,ceil(log(maxf(0.9,span))/log(1.5))),0.9,MAX_SPAN_KM)

static func center_for(point:Vector2,span:float)->Vector2:
	var step:=maxf(0.04,span/12.0)
	return (point/step).round()*step

static func resolution_for(span:float)->int:
	# A 513 grid remains worthwhile for the 50,000-ft band, where a streamed
	# cell still covers several screen pixels. Beyond a 64 km patch, 385 cells
	# already exceed useful projected density; 513 spent 44% more samples on
	# climate, geology, coast and normals without adding visible information.
	if span<=14.0:return 385
	if span<=32.0:return 257
	if span<=64.0:return MAX_RESOLUTION
	# A literal whole-planet patch needs the existing 80 km coast ceiling.
	if span>30720.0:return MAX_RESOLUTION
	return 385

static func preview_resolution(span:float)->int:
	# A continental preview must never be coarser than the ~83 km global mesh.
	# Close previews stay cheap; final meshes are installed atomically afterward.
	var cells:=32
	while span/float(cells)>80.0 and cells<MAX_RESOLUTION-1:cells*=2
	return mini(cells+1,resolution_for(span))

static func next_resolution(span:float,installed:int=0)->int:
	var first:=preview_resolution(span)
	if installed<first:return first
	# An intermediate grid makes new regional views useful promptly while the
	# final mesh continues in small slices. Never downgrade an installed grid.
	if installed<129:return mini(129,resolution_for(span))
	return resolution_for(span)

static func retain(cache:Array[Dictionary],completed:Dictionary)->void:
	# Only complete detail enters the cache. Preview grids can also exceed 33.
	if int(completed.resolution)!=resolution_for(float(completed.span)):return
	for index in range(cache.size()-1,-1,-1):
		if cache[index].center==completed.center and is_equal_approx(cache[index].span,completed.span):cache.remove_at(index)
	cache.push_front(completed)
	var vertices:=0
	for index in cache.size():
		vertices+=int(cache[index].resolution)*int(cache[index].resolution)
		if index>=CACHE_ENTRY_LIMIT or vertices>CACHE_VERTEX_BUDGET:
			cache.resize(index)
			break
