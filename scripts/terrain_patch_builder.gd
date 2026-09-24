extends RefCounted
## Builds one bounded terrain mesh in small main-thread slices. Only the finished
## mesh replaces the visible patch; height/color callables never cross threads.
var resolution:int
var span:float
var center:Vector2
var vertices:=PackedVector3Array()
var heights:=PackedFloat32Array()
var normals:=PackedVector3Array()
var colors:=PackedColorArray()
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

func _init(grid_resolution:int,patch_span:float,patch_center:Vector2,height_fn:Callable,color_fn:Callable,surface_fn:Callable=Callable(),season_fn:Callable=Callable(),prior_samples:Dictionary={})->void:
	resolution=grid_resolution; span=patch_span; center=patch_center
	sample_height=height_fn; sample_color=color_fn
	sample_surface=surface_fn
	season_sampler=season_fn
	heights.resize(resolution*resolution)
	vertices.resize(resolution*resolution); normals.resize(vertices.size()); colors.resize(vertices.size())
	indices.resize((resolution-1)*(resolution-1)*6)
	if sample_surface.is_valid():
		climate_uv.resize(vertices.size());geology_uv.resize(vertices.size())
	if season_sampler.is_valid():seasonal_amplitudes.resize(vertices.size())
	_configure_reuse(prior_samples)

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
	var height:=lerpf(lerpf(_raster_heights[a],_raster_heights[b],fx),lerpf(_raster_heights[c],_raster_heights[d],fx),fy)+0.0006
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
				var height:float=sample_height.call(x,z)+0.0006
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
