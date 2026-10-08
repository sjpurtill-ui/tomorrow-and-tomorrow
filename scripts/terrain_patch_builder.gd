extends RefCounted
## Builds one bounded terrain mesh in small main-thread slices. Only the finished
## mesh replaces the visible patch; height/color callables never cross threads.
##
## codex/map-speed: given the terrain's fused sampler (start()), the whole build
## runs on worker threads instead: row bands sample in parallel
## (TerrainPatchSampler, or the macro raster), then the last band to finish
## merges them, derives normals and the chart's cover, and builds the mesh and
## the height, relief and cover images, so the owner only swaps them in.
## Nothing on the worker touches the scene; `advance()` polls, `cancel()`
## abandons (the static registry below keeps an abandoned build alive until
## its threads have stopped), and `drain()` waits for every build to stop.
const PATCH_LIFT:=0.0006

## Keep the depth bias on uplands, but never lift shallow water into land.
## Physical heights and the zero shoreline stay untouched through the first
## dry metre; the existing bias returns smoothly between one and four metres.
static func surface_height(raw:float)->float:
	return raw+PATCH_LIFT*smoothstep(0.001,0.004,raw)

var resolution:int
var span:float
var center:Vector2
var vertices:=PackedVector3Array()
var heights:=PackedFloat32Array()
var normals:=PackedVector3Array()
var colors:=PackedColorArray()
## The land cover the chart reads (map_chart.gdshaderinc), four bytes a vertex
## in grid order: woodland, rainfall, warmth, land (255) or water (0).
var cover:=PackedByteArray()
var indices:=PackedInt32Array()
var cursor:=0
var phase:=0
var sample_height:Callable
var sample_color:Callable
var sample_surface:Callable
var season_sampler:Callable
var seasonal_amplitudes:=PackedFloat32Array()
var climate_uv:=PackedVector2Array()
var geology_uv:=PackedVector2Array()
var max_slice_usec:=0
var sampled_vertices:=0
var reused_vertices:=0
var reuse_center:=Vector2.ZERO
var reuse_span:=0.0
var reuse_resolution:=0
var reuse_stride:=1
var reuse_offset:=Vector2i.ZERO
var reuse_vertices:=PackedVector3Array()
var reuse_colors:=PackedColorArray()
var reuse_climate:=PackedVector2Array()
var reuse_geology:=PackedVector2Array()
var reuse_seasons:=PackedFloat32Array()
## Optional per-seed planet raster (terrain_macro_render.gd Raster). When set,
## every vertex is bilinearly filtered from it instead of calling the samplers;
## the owner only assigns one whose cell is no larger than this grid's spacing.
var macro_raster:RefCounted
var _raster_bound:=false
var _raster_heights:=PackedFloat32Array()
var _raster_seasons:=PackedFloat32Array()
var _raster_colors:=PackedInt32Array()
var _raster_fields:=PackedInt32Array()
var _raster_origin:=Vector2.ZERO
var _raster_inverse_cell:=Vector2.ONE
var _raster_columns:=0
var _raster_rows:=0
var _allocated:=false

## --- Worker builds (codex/map-speed) ---
## Rows a worker samples at a time: a cancel lands within one band.
const BAND_ROWS:=8
## Sampling threads. Two halve the wait; a third gained nothing measurable
## (every GDScript object call shares one lock in debug builds).
const WORKER_THREADS:=2
## TerrainPatchSampler; null keeps the main-thread slices above.
var sampler:RefCounted
## The world seed the sampler was built for: the owner drops the patch if
## the world changed while it was sampling.
var sample_seed:=0
var cancelled:=false
## Finished on the worker: the mesh, and the images the owner's textures are
## updated from (heights; heights with their mip chain; the cover with its).
var built_mesh:ArrayMesh
var height_image:Image
var relief_image:Image
var cover_image:Image
## Wall time from start() to the finished build, and the worker's own
## merge/normals/mesh/texture step within it.
var worker_usec:=0
var finish_usec:=0
var _group:=-1
var _bands:Array=[]
var _band_count:=0
var _bands_done:=0
var _mutex:Mutex
var _started_usec:=0
var _has_surface:=false
var _has_seasons:=false
## Builds whose threads may still run. Holding them here keeps an abandoned
## build alive until its bands return; reap() then waits on it (instantly).
static var _running:Array=[]
## Triangle indices depend only on the resolution: built once each.
static var _index_cache:Dictionary={}
static var _index_mutex:=Mutex.new()

func _init(grid_resolution:int,patch_span:float,patch_center:Vector2,height_fn:Callable,color_fn:Callable,surface_fn:Callable=Callable(),season_fn:Callable=Callable(),prior_samples:Dictionary={})->void:
	resolution=grid_resolution; span=patch_span; center=patch_center
	sample_height=height_fn; sample_color=color_fn
	sample_surface=surface_fn
	season_sampler=season_fn
	_configure_reuse(prior_samples)

## The sliced build's arrays, sized on its first slice (a worker build never
## needs them: it merges its bands instead).
func _allocate()->void:
	_allocated=true
	heights.resize(resolution*resolution)
	vertices.resize(resolution*resolution); normals.resize(vertices.size()); colors.resize(vertices.size())
	cover.resize(vertices.size()*4)
	indices.resize((resolution-1)*(resolution-1)*6)
	if sample_surface.is_valid():
		climate_uv.resize(vertices.size());geology_uv.resize(vertices.size())
	if season_sampler.is_valid():seasonal_amplitudes.resize(vertices.size())

func _configure_reuse(source:Dictionary)->void:
	# Raster-filtered samples are not authoritative observations.
	if int(source.get("macro_level",-1))>=0:return
	var count:=int(source.get("resolution",0))
	if count<2 or float(source.get("span",0.0))<=0.0:return
	var size:=count*count
	if source.get("vertices",PackedVector3Array()).size()!=size or source.get("colors",PackedColorArray()).size()!=size:return
	if sample_surface.is_valid() and (source.get("climate",PackedVector2Array()).size()!=size or source.get("geology",PackedVector2Array()).size()!=size):return
	if season_sampler.is_valid() and source.get("seasons",PackedFloat32Array()).size()!=size:return
	reuse_center=source.center;reuse_span=source.span;reuse_resolution=count
	reuse_vertices=source.vertices;reuse_colors=source.colors
	reuse_climate=source.get("climate",PackedVector2Array());reuse_geology=source.get("geology",PackedVector2Array())
	reuse_seasons=source.get("seasons",PackedFloat32Array())
	if reuse_span==span:
		var ratio:=float(resolution-1)/float(reuse_resolution-1)
		var stride:=roundi(ratio)
		var offset:=(reuse_center-center)/(span/float(resolution-1))
		if stride>1 and ratio==float(stride) and offset.distance_squared_to(offset.round())<.000001:
			reuse_stride=stride;reuse_offset=Vector2i(offset.round())

func _copy_shared_sample(x:float,z:float)->bool:
	var cells:=reuse_resolution-1
	var column:=roundi((x-reuse_center.x)/reuse_span*float(cells)+float(cells)*0.5)
	var row:=roundi((z-reuse_center.y)/reuse_span*float(cells)+float(cells)*0.5)
	if column<0 or column>=reuse_resolution or row<0 or row>=reuse_resolution:return false
	var index:=row*reuse_resolution+column
	var point:=reuse_vertices[index]
	# Never interpolate stored observations or accept a nearby cell. Only the
	# identical renderable world coordinate can replace an authoritative sample.
	if point.x!=x or point.z!=z:return false
	vertices[cursor]=point;heights[cursor]=point.y;colors[cursor]=reuse_colors[index]
	if sample_surface.is_valid():climate_uv[cursor]=reuse_climate[index];geology_uv[cursor]=reuse_geology[index]
	if season_sampler.is_valid():seasonal_amplitudes[cursor]=reuse_seasons[index]
	reused_vertices+=1
	return true

func completed_samples()->Dictionary:
	assert(phase==2)
	# Packed arrays share immutable storage until a writer detaches them. The
	# owner retains only its bounded mesh cache plus the currently visible patch.
	return {"center":center,"span":span,"resolution":resolution,"vertices":vertices,"colors":colors,"climate":climate_uv,"geology":geology_uv,"seasons":seasonal_amplitudes,"macro_level":int(macro_raster.get("level")) if macro_raster!=null else -1}

func _bind_raster()->void:
	_raster_bound=true
	if macro_raster==null:return
	# Filtered raster samples are never mixed with exact ones in either direction.
	reuse_resolution=0
	_raster_heights=macro_raster.get("heights");_raster_seasons=macro_raster.get("seasons")
	_raster_colors=macro_raster.get("colors");_raster_fields=macro_raster.get("fields")
	_raster_origin=macro_raster.get("origin")
	var cell:Vector2=macro_raster.get("cell")
	_raster_inverse_cell=Vector2(1.0/cell.x,1.0/cell.y)
	_raster_columns=int(macro_raster.get("columns"));_raster_rows=int(macro_raster.get("rows"))

func _sample_raster(x:float,z:float)->void:
	var u:=(x-_raster_origin.x)*_raster_inverse_cell.x
	var v:=(z-_raster_origin.y)*_raster_inverse_cell.y
	var column:=clampi(floori(u),0,_raster_columns-2)
	var row:=clampi(floori(v),0,_raster_rows-2)
	var fx:=clampf(u-float(column),0.0,1.0);var fy:=clampf(v-float(row),0.0,1.0)
	var a:=row*_raster_columns+column;var b:=a+1;var c:=a+_raster_columns;var d:=c+1
	var height:=surface_height(lerpf(lerpf(_raster_heights[a],_raster_heights[b],fx),lerpf(_raster_heights[c],_raster_heights[d],fx),fy))
	vertices[cursor]=Vector3(x,height,z)
	heights[cursor]=height
	colors[cursor]=Color.hex(_raster_colors[a]).lerp(Color.hex(_raster_colors[b]),fx).lerp(Color.hex(_raster_colors[c]).lerp(Color.hex(_raster_colors[d]),fx),fy)
	if sample_surface.is_valid():
		var f:=Color.hex(_raster_fields[a]).lerp(Color.hex(_raster_fields[b]),fx).lerp(Color.hex(_raster_fields[c]).lerp(Color.hex(_raster_fields[d]),fx),fy)
		climate_uv[cursor]=Vector2(1.0+f.r,f.g);geology_uv[cursor]=Vector2(f.b,f.a)
	if season_sampler.is_valid():
		seasonal_amplitudes[cursor]=lerpf(lerpf(_raster_seasons[a],_raster_seasons[b],fx),lerpf(_raster_seasons[c],_raster_seasons[d],fx),fy)
	sampled_vertices+=1

func advance(budget_usec:int=2500)->bool:
	if sampler!=null:return _poll_worker()
	if not _allocated:_allocate()
	var started:=Time.get_ticks_usec()
	var total:=vertices.size()
	var spacing:=span/float(resolution-1)
	# Close relief uses a twenty-metre baseline. Coarse regional shading averages
	# two cells so undersampled ridges do not become alternating bright/dark facets.
	# Geometry and authoritative heights are unchanged.
	var normal_radius:=maxi(1,ceili(maxf(0.02,spacing*2.0*smoothstep(0.01,0.15,spacing))/spacing))
	if not _raster_bound:_bind_raster()
	while phase<2:
		var x_index:=cursor%resolution
		var z_index:=cursor/resolution
		if phase==0:
			# Sample at the coordinate actually stored by the float32 mesh. Adjacent
			# patches then agree even when far-world arithmetic rounds differently.
			var half_cells:=float(resolution-1)*0.5
			var point:=Vector2(center.x+(float(x_index)-half_cells)*spacing,center.y+(float(z_index)-half_cells)*spacing)
			var x:=float(point.x);var z:=float(point.y)
			# A coarse preview shares only every third/fourth fine-grid node.
			# Skip the impossible lookups before touching its packed sample arrays.
			if macro_raster!=null:
				_sample_raster(x,z)
				cursor+=1
				if cursor>=total: phase+=1; cursor=0
				if cursor%8==0 and Time.get_ticks_usec()-started>=budget_usec: break
				continue
			var shared_node:=reuse_resolution>0 and (reuse_stride==1 or ((x_index-reuse_offset.x)%reuse_stride==0 and (z_index-reuse_offset.y)%reuse_stride==0))
			if not shared_node or not _copy_shared_sample(x,z):
				var height:=surface_height(float(sample_height.call(x,z)))
				vertices[cursor]=Vector3(x,height,z)
				heights[cursor]=height
				colors[cursor]=sample_color.call(x,z,height)
				if sample_surface.is_valid():
					var fields:Vector4=sample_surface.call(x,z,height)
					climate_uv[cursor]=Vector2(fields.x,fields.y);geology_uv[cursor]=Vector2(fields.z,fields.w)
				if season_sampler.is_valid():seasonal_amplitudes[cursor]=season_sampler.call(x,z,height)
				sampled_vertices+=1
		else:
			var left:=maxi(0,x_index-normal_radius); var right:=mini(resolution-1,x_index+normal_radius)
			var up:=maxi(0,z_index-normal_radius); var down:=mini(resolution-1,z_index+normal_radius)
			var dx:=(vertices[z_index*resolution+right].y-vertices[z_index*resolution+left].y)/(float(right-left)*spacing)
			var dz:=(vertices[down*resolution+x_index].y-vertices[up*resolution+x_index].y)/(float(down-up)*spacing)
			normals[cursor]=Vector3(-dx,1.0,-dz).normalized()
			var byte:=cursor*4
			cover[byte]=clampi(roundi(colors[cursor].a*255.0),0,255)
			if not climate_uv.is_empty():
				cover[byte+1]=clampi(roundi((climate_uv[cursor].x-1.0)*255.0),0,255)
				cover[byte+2]=clampi(roundi(climate_uv[cursor].y*255.0),0,255)
			cover[byte+3]=255 if vertices[cursor].y>0.0 else 0
			if x_index<resolution-1 and z_index<resolution-1:
				var a:=cursor; var b:=a+1; var d:=a+resolution; var c:=d+1
				var offset:=(z_index*(resolution-1)+x_index)*6
				var corners:=[a,b,c,a,c,d] if (x_index+z_index)%2==0 else [a,b,d,b,c,d]
				for corner in 6: indices[offset+corner]=corners[corner]
		cursor+=1
		if cursor>=total: phase+=1; cursor=0
		# Height/climate sampling is substantially more expensive than moving one
		# packed vertex. Check often enough that a nominal 1.4 ms navigation slice
		# cannot run for several additional milliseconds before yielding.
		if cursor%2==0 and Time.get_ticks_usec()-started>=budget_usec: break
	max_slice_usec=maxi(max_slice_usec,Time.get_ticks_usec()-started)
	return phase==2

func commit()->ArrayMesh:
	assert(phase==2)
	if built_mesh!=null:return built_mesh
	return _make_mesh()

func _make_mesh()->ArrayMesh:
	var arrays:Array=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_COLOR]=colors; arrays[Mesh.ARRAY_INDEX]=indices
	if not climate_uv.is_empty():
		arrays[Mesh.ARRAY_TEX_UV]=climate_uv;arrays[Mesh.ARRAY_TEX_UV2]=geology_uv
	var flags:=0
	if not seasonal_amplitudes.is_empty():
		arrays[Mesh.ARRAY_CUSTOM0]=seasonal_amplitudes
		flags=Mesh.ARRAY_CUSTOM_R_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},flags)
	return mesh

## --- Worker builds (codex/map-speed) ---

## Builds the whole patch on worker threads with `patch_sampler`, the terrain's
## fused sampler (a macro raster, when assigned, still takes precedence).
## Main thread; call once, after macro_raster is set.
func start(patch_sampler:RefCounted)->void:
	reap()
	# The fused sampler fills every channel; a build without them stays sliced.
	if patch_sampler==null or (macro_raster==null and not (sample_surface.is_valid() and season_sampler.is_valid())):return
	sampler=patch_sampler
	sample_seed=int(patch_sampler.get("seed_value"))
	_has_surface=sample_surface.is_valid()
	_has_seasons=season_sampler.is_valid()
	_bind_raster()
	_mutex=Mutex.new()
	_band_count=ceili(float(resolution)/float(BAND_ROWS))
	_bands.resize(_band_count)
	_started_usec=Time.get_ticks_usec()
	_running.append(self)
	_group=WorkerThreadPool.add_group_task(_run_band,_band_count,WORKER_THREADS,true,"Terrain patch")

## Whether this build runs on worker threads.
func uses_worker()->bool:
	return sampler!=null

## Abandons the build: its bands stop at their next row band and the
## finishing step is skipped. The owner must drop the build.
func cancel()->void:
	cancelled=true

func _poll_worker()->bool:
	if _group>=0:
		if not WorkerThreadPool.is_group_task_completed(_group):
			reap()
			return false
		var started:=Time.get_ticks_usec()
		WorkerThreadPool.wait_for_group_task_completion(_group)
		_group=-1
		_running.erase(self)
		max_slice_usec=maxi(max_slice_usec,Time.get_ticks_usec()-started)
	return phase==2

## Worker thread: one band of rows, and for the last band to finish, the
## whole patch.
func _run_band(band:int)->void:
	if not cancelled:
		var first:=band*BAND_ROWS
		var count:=mini(BAND_ROWS,resolution-first)
		_bands[band]=_sample_raster_band(first,count) if macro_raster!=null else sampler.sample_rows(self,first,count,true)
	_mutex.lock()
	_bands_done+=1
	var last:=_bands_done==_band_count
	_mutex.unlock()
	if last and not cancelled:_finish_on_worker()

## Worker thread, after every band: the patch as the sliced build leaves it,
## then its mesh and textures.
func _finish_on_worker()->void:
	var started:=Time.get_ticks_usec()
	for band:Array in _bands:
		heights.append_array(band[0]);vertices.append_array(band[1]);colors.append_array(band[2])
		if _has_surface:climate_uv.append_array(band[3]);geology_uv.append_array(band[4])
		if _has_seasons:seasonal_amplitudes.append_array(band[5])
		sampled_vertices+=int(band[6]);reused_vertices+=int(band[7])
	_bands.clear()
	if cancelled:return
	var total:=vertices.size()
	var spacing:=span/float(resolution-1)
	var normal_radius:=maxi(1,ceili(maxf(0.02,spacing*2.0*smoothstep(0.01,0.15,spacing))/spacing))
	normals.resize(total)
	cover.resize(total*4)
	var has_climate:=not climate_uv.is_empty()
	var index:=0
	for z_index in resolution:
		var up:=maxi(0,z_index-normal_radius); var down:=mini(resolution-1,z_index+normal_radius)
		var row:=z_index*resolution
		var dz_scale:=float(down-up)*spacing
		for x_index in resolution:
			# Exactly the sliced build's normal and cover (advance(), phase 1).
			var left:=maxi(0,x_index-normal_radius); var right:=mini(resolution-1,x_index+normal_radius)
			var dx:=(vertices[row+right].y-vertices[row+left].y)/(float(right-left)*spacing)
			var dz:=(vertices[down*resolution+x_index].y-vertices[up*resolution+x_index].y)/dz_scale
			normals[index]=Vector3(-dx,1.0,-dz).normalized()
			var byte:=index*4
			cover[byte]=clampi(roundi(colors[index].a*255.0),0,255)
			if has_climate:
				var climate:=climate_uv[index]
				cover[byte+1]=clampi(roundi((climate.x-1.0)*255.0),0,255)
				cover[byte+2]=clampi(roundi(climate.y*255.0),0,255)
			cover[byte+3]=255 if vertices[index].y>0.0 else 0
			index+=1
		if cancelled:return
	indices=_indices_for(resolution)
	phase=2
	if cancelled:return
	built_mesh=_make_mesh()
	# The images behind the owner's textures (local_terrain.gd
	# _patch_images): the heights as they are, then box-filtered level by
	# level for the chart, and the cover likewise.
	height_image=Image.create_from_data(resolution,resolution,false,Image.FORMAT_RF,heights.to_byte_array())
	relief_image=height_image.duplicate() as Image
	relief_image.generate_mipmaps()
	cover_image=Image.create_from_data(resolution,resolution,false,Image.FORMAT_RGBA8,cover)
	cover_image.generate_mipmaps()
	var finished:=Time.get_ticks_usec()
	finish_usec=finished-started
	worker_usec=finished-_started_usec

## Worker thread: _sample_raster for a band of rows.
func _sample_raster_band(first_row:int,row_count:int)->Array:
	var spacing:=span/float(resolution-1)
	var half_cells:=float(resolution-1)*0.5
	var nodes:=resolution*row_count
	var band_heights:=PackedFloat32Array();band_heights.resize(nodes)
	var band_vertices:=PackedVector3Array();band_vertices.resize(nodes)
	var band_colors:=PackedColorArray();band_colors.resize(nodes)
	var band_climate:=PackedVector2Array()
	var band_geology:=PackedVector2Array()
	var band_seasons:=PackedFloat32Array()
	if _has_surface:band_climate.resize(nodes);band_geology.resize(nodes)
	if _has_seasons:band_seasons.resize(nodes)
	var index:=0
	for z_index in range(first_row,first_row+row_count):
		for x_index in resolution:
			var point:=Vector2(center.x+(float(x_index)-half_cells)*spacing,center.y+(float(z_index)-half_cells)*spacing)
			var x:=float(point.x);var z:=float(point.y)
			var u:=(x-_raster_origin.x)*_raster_inverse_cell.x
			var v:=(z-_raster_origin.y)*_raster_inverse_cell.y
			var column:=clampi(floori(u),0,_raster_columns-2)
			var row:=clampi(floori(v),0,_raster_rows-2)
			var fx:=clampf(u-float(column),0.0,1.0);var fy:=clampf(v-float(row),0.0,1.0)
			var a:=row*_raster_columns+column;var b:=a+1;var c:=a+_raster_columns;var d:=c+1
			var height:=surface_height(lerpf(lerpf(_raster_heights[a],_raster_heights[b],fx),lerpf(_raster_heights[c],_raster_heights[d],fx),fy))
			band_vertices[index]=Vector3(x,height,z)
			band_heights[index]=height
			band_colors[index]=Color.hex(_raster_colors[a]).lerp(Color.hex(_raster_colors[b]),fx).lerp(Color.hex(_raster_colors[c]).lerp(Color.hex(_raster_colors[d]),fx),fy)
			if _has_surface:
				var f:=Color.hex(_raster_fields[a]).lerp(Color.hex(_raster_fields[b]),fx).lerp(Color.hex(_raster_fields[c]).lerp(Color.hex(_raster_fields[d]),fx),fy)
				band_climate[index]=Vector2(1.0+f.r,f.g);band_geology[index]=Vector2(f.b,f.a)
			if _has_seasons:
				band_seasons[index]=lerpf(lerpf(_raster_seasons[a],_raster_seasons[b],fx),lerpf(_raster_seasons[c],_raster_seasons[d],fx),fy)
			index+=1
	return [band_heights,band_vertices,band_colors,band_climate,band_geology,band_seasons,nodes,0]

## The sliced build's triangle order for a grid of this resolution.
static func _indices_for(grid:int)->PackedInt32Array:
	_index_mutex.lock()
	var cached:PackedInt32Array=_index_cache.get(grid,PackedInt32Array())
	_index_mutex.unlock()
	if not cached.is_empty():return cached
	var built:=PackedInt32Array();built.resize((grid-1)*(grid-1)*6)
	var offset:=0
	for z_index in grid-1:
		for x_index in grid-1:
			var a:=z_index*grid+x_index; var b:=a+1; var d:=a+grid; var c:=d+1
			if (x_index+z_index)%2==0:
				built[offset]=a;built[offset+1]=b;built[offset+2]=c;built[offset+3]=a;built[offset+4]=c;built[offset+5]=d
			else:
				built[offset]=a;built[offset+1]=b;built[offset+2]=d;built[offset+3]=b;built[offset+4]=c;built[offset+5]=d
			offset+=6
	_index_mutex.lock()
	_index_cache[grid]=built
	_index_mutex.unlock()
	return built

## Main thread: forgets builds whose threads have all returned.
static func reap()->void:
	for index in range(_running.size()-1,-1,-1):
		var job:RefCounted=_running[index]
		var group:int=job.get("_group")
		if group>=0:
			if not WorkerThreadPool.is_group_task_completed(group):continue
			WorkerThreadPool.wait_for_group_task_completion(group)
			job.set("_group",-1)
		_running.remove_at(index)

## Main thread: waits for the threads of every abandoned build (its owner
## is leaving the tree, or a test is done with it). A build another owner
## still wants runs on: a worker never touches its owner, so nothing it
## holds can be freed under it.
static func drain()->void:
	for index in range(_running.size()-1,-1,-1):
		var job:RefCounted=_running[index]
		if not bool(job.get("cancelled")):continue
		var group:int=job.get("_group")
		if group>=0:
			WorkerThreadPool.wait_for_group_task_completion(group)
			job.set("_group",-1)
		_running.remove_at(index)
