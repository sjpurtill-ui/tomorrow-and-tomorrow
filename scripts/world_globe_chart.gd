extends RefCounted
## The world our people know, measured and drawn for the world view
## (hud/world_globe.gd). It reads only the revealed records CivilizationSystem
## keeps (circles and trails in map kilometres) and never saves anything: the
## growth history comes from the day each record already carries.
##
## The measure is exact and area-correct. The planet map is equirectangular
## (x true at the equator, z true along a meridian), so each strip of map is
## weighted by cos(latitude). Every texel row is cut into 8 sub-row bands; each
## band keeps the union of the revealed shapes crossing it as merged x
## intervals, found analytically for circles and capsules (trail segments),
## each with the share of the band's height the shape covers there (so a
## straight east-west trail edge is counted exactly). Overlaps are counted
## once, and each piece of ground is credited to the record that first showed
## it (scouts, envoys, travel, trade, war).
##
## The known-map image is 2048 x 1024 RGBA8, premultiplied by how much of each
## texel is known: R known share, G land, B height, A greenness of the land.
## A texel nobody has seen is all zero, and land, height and greenness are
## sampled only at points inside the revealed ground, so the image cannot
## carry a coastline, a height or a colour from anywhere the people have not
## been. Updates run on a worker thread; the map only grows, so new records
## are merged in without redrawing the rest.

const COLUMNS:=2048
const ROWS:=1024
const SUBROWS:=8
const WIDTH_KM:=40075.0
const DEPTH_KM:=20004.0
const TEXEL_X:=WIDTH_KM/float(COLUMNS)
const TEXEL_Z:=DEPTH_KM/float(ROWS)
const SUB_Z:=TEXEL_Z/float(SUBROWS)
const SUBROW_COUNT:=ROWS*SUBROWS
## The same sea level PlanetEnvironment.is_land uses.
const LAND_LEVEL:=0.015
## Height encoding for the B channel (world units, sea floor to high peaks).
const HEIGHT_LOW:=-4.0
const HEIGHT_HIGH:=8.0
## Sample positions inside a texel: two sub-rows and two columns, symmetric.
const SAMPLE_SUBROWS:=[2,5]
const SAMPLE_COLUMNS:=[0.3125,0.6875]
const CATEGORIES:=["travel","scouts","envoys","trade","war","other"]
const YEAR_DAYS:=365

# --- Main-thread bookkeeping (which records are already in the chart) -------
var world_seed:=-1
var _seen_count:=0
var _first_key:=""
var _last_key:=""
var _last_points:=0
var _queued:Array=[]
var _queued_reset:=false
var _task_id:=-1
var _task_reset:=false
## Bumped on every published result; views compare it to know when to redraw.
var revision:=0
var image:Image
## The world the published image and figures belong to.
var image_seed:=-1
var stats:Dictionary=empty_stats()
var height_mode:="none"
var _job_seed:=-1
## GPU copies of the published image, kept by the view between openings
## (created and updated on the main thread only).
var textures:Array=[]
var texture_front:=0
var texture_revision:=-1
var _city_source_fn:Callable=Callable()
var _city_source_book:Dictionary={}
var _city_source_asked:=false

# --- Worker-owned state (touched only inside a job) --------------------------
var _rows:Dictionary={}
var _row_length:Dictionary={}
var _weights:=PackedFloat64Array()
var _surface:=0.0
var _area:=PackedFloat32Array()
var _land:=PackedFloat32Array()
var _pixels:=PackedByteArray()
var _known:=PackedInt32Array()
var _gain_days:=PackedInt32Array()
var _gain_values:=PackedFloat64Array()
var _gain_categories:=PackedByteArray()
var _category_totals:=PackedFloat64Array()
var _job_items:Array=[]
var _job_result:Dictionary={}
## Height source for the job: a planet raster (LocalTerrain's level-0 render
## lattice), else an exact sampler Callable(Vector2)->float.
var _raster_heights:=PackedFloat32Array()
var _raster_colors:=PackedInt32Array()
var _raster_origin:=Vector2.ZERO
var _raster_cell:=Vector2.ONE
var _raster_columns:=0
var _raster_rows:=0
var _exact_height:Callable=Callable()

static var _shared:RefCounted


## One chart per running game, reused by every opening of the world view.
static func shared()->RefCounted:
	if _shared==null:_shared=load("res://scripts/world_globe_chart.gd").new()
	return _shared


static func empty_stats()->Dictionary:
	var by:={}
	for id:String in CATEGORIES:by[id]=0.0
	return {"known_km2":0.0,"known_fraction":0.0,"land_fraction":0.0,"sea_fraction":0.0,"surface_km2":surface_km2(),"by_category":by,"days":PackedInt32Array(),"gains":PackedFloat64Array(),"records":0,"texels":0}


func _init()->void:
	_weights=subrow_weights()
	_surface=0.0
	for s in SUBROW_COUNT:_surface+=_weights[s]*WIDTH_KM


# --- Geometry ------------------------------------------------------------------

## The z (km) at the centre of a sub-row.
static func subrow_z(s:int)->float:
	return -DEPTH_KM*0.5+(float(s)+0.5)*SUB_Z


## Latitude in radians of a map z (north is -z).
static func latitude(z:float)->float:
	return -z/(DEPTH_KM*0.5)*PI*0.5


## Area weight of one kilometre of map x on each sub-row: cos(latitude) times
## the sub-row's height, so length x weight is true surface area in km2.
static func subrow_weights()->PackedFloat64Array:
	var weights:=PackedFloat64Array();weights.resize(SUBROW_COUNT)
	for s in SUBROW_COUNT:weights[s]=cos(latitude(subrow_z(s)))*SUB_Z
	return weights


## The whole surface as this measure counts it (about 510 million km2).
static func surface_km2()->float:
	var total:=0.0
	var weights:=subrow_weights()
	for s in SUBROW_COUNT:total+=weights[s]*WIDTH_KM
	return total


## Where a horizontal line z crosses the disc of radius r around the segment
## a-b (a capsule; a circle when a==b). Vector2(INF,-INF) when it misses.
static func capsule_span(a:Vector2,b:Vector2,r:float,z:float)->Vector2:
	var lo:=INF
	var hi:=-INF
	var dz:=z-a.y
	if absf(dz)<=r:
		var h:=sqrt(r*r-dz*dz)
		lo=a.x-h;hi=a.x+h
	var d:=b-a
	var length:=d.length()
	if length<=0.000001:return Vector2(lo,hi)
	dz=z-b.y
	if absf(dz)<=r:
		var h:=sqrt(r*r-dz*dz)
		lo=minf(lo,b.x-h);hi=maxf(hi,b.x+h)
	var ux:=d.x/length
	var uz:=d.y/length
	var band_lo:=-INF
	var band_hi:=INF
	# Along the segment: 0 <= (x-ax)ux + (z-az)uz <= length.
	var along:=(z-a.y)*uz
	if absf(ux)>0.000000001:
		var x0:=a.x+(-along)/ux
		var x1:=a.x+(length-along)/ux
		band_lo=maxf(band_lo,minf(x0,x1));band_hi=minf(band_hi,maxf(x0,x1))
	elif along<0.0 or along>length:return Vector2(lo,hi)
	# Across it: -r <= -(x-ax)uz + (z-az)ux <= r.
	var across:=(z-a.y)*ux
	if absf(uz)>0.000000001:
		var y0:=a.x+(across-r)/uz
		var y1:=a.x+(across+r)/uz
		band_lo=maxf(band_lo,minf(y0,y1));band_hi=minf(band_hi,maxf(y0,y1))
	elif absf(across)>r:return Vector2(lo,hi)
	if band_lo<=band_hi:
		lo=minf(lo,band_lo);hi=maxf(hi,band_hi)
	return Vector2(lo,hi)


## What kind of knowing a revealed record's source describes.
static func category(source:String)->String:
	var s:=source.to_lower()
	var words:=s.replace(":"," ").replace(";"," ").replace(","," ").split(" ",false)
	if s.contains("diplomat") or s.contains("envoy"):return "envoys"
	if s.contains("found") or s.contains("travel"):return "travel"
	if "war" in words or "army" in words or s.contains("campaign") or s.contains("battle") or s.contains("siege"):return "war"
	if s.contains("scout") or s.contains("reconnaissance") or s.contains("observ") or s.contains("returned route") or s.contains("contact"):return "scouts"
	if s.contains("trade") or s.contains("caravan") or s.contains("merchant") or s.contains("exchange") or s.contains("market"):return "trade"
	if s.contains("camp") or s.contains("home") or s.contains("settle"):return "travel"
	return "other"


static func record_key(area_variant:Variant)->String:
	var area:Dictionary=area_variant if area_variant is Dictionary else {}
	return "%s|%s|%.4f|%.4f|%.3f|%d" % [String(area.get("kind","")),String(area.get("source","")),float(area.get("x",0.0)),float(area.get("z",0.0)),float(area.get("radius",0.0)),int(area.get("day",0))]


# --- Globe geometry (shared by the view, its picking and the tests) ----------

## Map kilometres -> Vector2(latitude, longitude) in radians.
static func lat_lon(position:Vector2)->Vector2:
	return Vector2(latitude(position.y),position.x/(WIDTH_KM*0.5)*PI)


## Latitude and longitude (radians) -> map kilometres.
static func map_position(lat:float,lon:float)->Vector2:
	return Vector2(wrapf(lon,-PI,PI)/PI*WIDTH_KM*0.5,-clampf(lat,-PI*0.5,PI*0.5)/(PI*0.5)*DEPTH_KM*0.5)


## Unit vector on the globe: y to the north pole, z through longitude 0.
static func globe_vector(lat:float,lon:float)->Vector3:
	return Vector3(cos(lat)*sin(lon),sin(lat),cos(lat)*cos(lon))


static func vector_lat_lon(v:Vector3)->Vector2:
	var n:=v.normalized()
	return Vector2(asin(clampf(n.y,-1.0,1.0)),atan2(n.x,n.z))


## Rotation taking globe vectors into view space, where the point (lat, lon)
## faces the viewer (+z) with north up, turned by `roll` about the view axis
## (the map's own heading while the view takes over from it).
static func view_basis(lat:float,lon:float,roll:float=0.0)->Basis:
	var facing:=Basis(Vector3.RIGHT,lat)*Basis(Vector3.UP,-lon)
	return facing if roll==0.0 else Basis(Vector3.BACK,roll)*facing


## A screen point -> the globe vector under it, or Vector3.ZERO off the globe.
## `center` is the globe's centre on screen, `half_height` half the view height
## in pixels, `distance` the eye's distance in globe radii.
static func screen_to_globe(screen:Vector2,center:Vector2,half_height:float,distance:float,tan_half_fov:float,basis:Basis)->Vector3:
	var p:=(screen-center)/maxf(1.0,half_height)
	var direction:=Vector3(p.x*tan_half_fov,-p.y*tan_half_fov,-1.0).normalized()
	var eye:=Vector3(0,0,distance)
	var b:=eye.dot(direction)
	var discriminant:=b*b-(distance*distance-1.0)
	if discriminant<0.0:return Vector3.ZERO
	var hit:=eye+direction*(-b-sqrt(discriminant))
	return basis.inverse()*hit.normalized()


## The map position (km) under a screen point, or Vector2.INF off the globe:
## where a click on the globe sends the map.
static func map_point_at(screen:Vector2,center:Vector2,half_height:float,distance:float,tan_half_fov:float,basis:Basis)->Vector2:
	var v:=screen_to_globe(screen,center,half_height,distance,tan_half_fov,basis)
	if v==Vector3.ZERO:return Vector2.INF
	var lat_lon:=vector_lat_lon(v)
	return map_position(lat_lon.x,lat_lon.y)


## A globe vector -> Vector3(screen x, screen y, facing) where facing > 0 means
## the point is on the side of the globe the eye can see.
static func globe_to_screen(v:Vector3,center:Vector2,half_height:float,distance:float,tan_half_fov:float,basis:Basis)->Vector3:
	var p:=basis*v
	var eye_z:=distance-p.z
	if eye_z<=0.0001:return Vector3(center.x,center.y,-1.0)
	var screen:=center+Vector2(p.x/eye_z,-p.y/eye_z)/tan_half_fov*half_height
	# Visible when the surface faces the eye: the limb is where p . (eye - p) = 0.
	var facing:=p.dot(Vector3(0,0,distance)-p)
	return Vector3(screen.x,screen.y,facing)


## The globe's radius on screen in pixels.
static func screen_radius(half_height:float,distance:float,tan_half_fov:float)->float:
	return tan(asin(1.0/maxf(1.0001,distance)))/tan_half_fov*half_height


# --- Words ---------------------------------------------------------------------

## A share of the world, with two significant figures and never "0%" when
## anything at all is known: 0.0032%, 0.40%, 1.2%, 12%.
static func percent_text(fraction:float)->String:
	var value:=fraction*100.0
	if value<=0.0:return "0%"
	if value>=99.95:return "100%"
	var exponent:=floori(log(value)/log(10.0))
	var decimals:=maxi(0,1-exponent)
	var rounded:=snappedf(value,pow(10.0,-decimals))
	if rounded>=pow(10.0,exponent+1)-0.0000001:
		decimals=maxi(0,decimals-1)
		rounded=snappedf(value,pow(10.0,-decimals))
	return ("%."+str(decimals)+"f%%") % rounded


## How much of the world was known on a given day, from the records' own days.
func known_fraction_at(day:int)->float:
	var days:PackedInt32Array=stats.get("days",PackedInt32Array())
	var gains:PackedFloat64Array=stats.get("gains",PackedFloat64Array())
	var total:=0.0
	for index in mini(days.size(),gains.size()):
		if days[index]<=day:total+=gains[index]
	return total/maxf(1.0,float(stats.get("surface_km2",surface_km2())))


# --- Sync (main thread) -------------------------------------------------------

## Brings the chart up to date with the revealed records. Starts a worker job
## when there is anything new; returns true when a job was started. Both
## sources are asked for only when needed:
##   city_sources()->{"x|z" (rounded km): source of that town's report}, so a
##     town seen by an army or an envoy credits the ground to them;
##   height_source()->{heights, colors, origin, cell, columns, rows} for a
##     planet raster, or {exact: Callable(Vector2)->float}.
func refresh(areas:Array,seed_value:int,city_sources:Callable=Callable(),height_source:Callable=Callable(),threaded:=true)->bool:
	_sync(areas,seed_value,city_sources)
	if _task_id>=0:return false
	if _queued.is_empty() and not _queued_reset:return false
	var heights:Variant=height_source.call() if height_source.is_valid() else {}
	_start_job(heights if heights is Dictionary else {},threaded)
	return true


## True when the published image and figures belong to this world.
func current(seed_value:int)->bool:
	return image!=null and image_seed==seed_value


## Polls a running job; true when a new result was published this call.
func poll()->bool:
	if _task_id<0:return false
	if not WorkerThreadPool.is_task_completed(_task_id):return false
	WorkerThreadPool.wait_for_task_completion(_task_id)
	_task_id=-1
	_publish()
	return true


func busy()->bool:
	return _task_id>=0


## Finishes any running job synchronously (tests, capture harness, shutdown).
func finish()->void:
	if _task_id>=0:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id=-1
		_publish()


func _sync(areas:Array,seed_value:int,city_sources:Callable)->void:
	_city_source_fn=city_sources
	_city_source_book={}
	_city_source_asked=false
	var count:=areas.size()
	var rebuild:=seed_value!=world_seed or count<_seen_count
	if not rebuild and _seen_count>0:
		rebuild=record_key(areas[0])!=_first_key or record_key(areas[_seen_count-1])!=_last_key
	if rebuild:
		world_seed=seed_value
		_queued.clear()
		_queued_reset=true
		_seen_count=0
		_last_points=0
	elif _seen_count>0:
		# The newest trail may have been walked further since it was charted.
		var last:Dictionary=areas[_seen_count-1]
		var points:Array=last.get("points",[])
		if String(last.get("kind",""))=="trail" and points.size()>_last_points and _last_points>=1:
			_queued.append(_item(last.duplicate(true),_last_points-1))
	for index in range(_seen_count,count):
		var area:Dictionary=areas[index]
		# The newest record may still grow in place; the job gets its own copy.
		_queued.append(_item(area.duplicate(true) if index==count-1 else area,0))
	_seen_count=count
	if count>0:
		_first_key=record_key(areas[0])
		_last_key=record_key(areas[count-1])
		var newest:Dictionary=areas[count-1]
		_last_points=(newest.get("points",[]) as Array).size() if String(newest.get("kind",""))=="trail" else 0
	else:
		_first_key="";_last_key="";_last_points=0


func _item(area:Dictionary,first_point:int)->Array:
	var source:=String(area.get("source",""))
	var kind:=category(source)
	if source=="observed city" and _city_source_fn.is_valid():
		if not _city_source_asked:
			var book:Variant=_city_source_fn.call()
			_city_source_book=book if book is Dictionary else {}
			_city_source_asked=true
		var key:="%d|%d" % [roundi(float(area.get("x",0.0))),roundi(float(area.get("z",0.0)))]
		if _city_source_book.has(key):
			var reported:=category(String(_city_source_book[key]))
			if reported!="other":kind=reported
	return [area,first_point,CATEGORIES.find(kind)]


func _start_job(height_source:Dictionary,threaded:bool)->void:
	_job_seed=world_seed
	_job_items=_queued.duplicate()
	_queued.clear()
	_task_reset=_queued_reset
	_queued_reset=false
	_raster_heights=height_source.get("heights",PackedFloat32Array())
	_raster_colors=height_source.get("colors",PackedInt32Array())
	_raster_origin=height_source.get("origin",Vector2.ZERO)
	_raster_cell=height_source.get("cell",Vector2.ONE)
	_raster_columns=int(height_source.get("columns",0))
	_raster_rows=int(height_source.get("rows",0))
	_exact_height=height_source.get("exact",Callable())
	height_mode="raster" if _raster_columns>1 and _raster_heights.size()==_raster_columns*_raster_rows else ("exact" if _exact_height.is_valid() else "none")
	if threaded:
		_task_id=WorkerThreadPool.add_task(_run_job,false,"World chart")
	else:
		_run_job()
		_publish()


func _publish()->void:
	if _job_result.is_empty():return
	image=_job_result.image
	stats=_job_result.stats
	image_seed=_job_seed
	_job_result={}
	revision+=1


# --- The job (worker thread) --------------------------------------------------

func _reset_state()->void:
	_rows.clear()
	_row_length.clear()
	_area=PackedFloat32Array();_area.resize(COLUMNS*ROWS)
	_land=PackedFloat32Array();_land.resize(COLUMNS*ROWS)
	_pixels=PackedByteArray();_pixels.resize(COLUMNS*ROWS*4)
	_known=PackedInt32Array()
	_gain_days=PackedInt32Array()
	_gain_values=PackedFloat64Array()
	_gain_categories=PackedByteArray()
	_category_totals=PackedFloat64Array();_category_totals.resize(CATEGORIES.size())


func _run_job()->void:
	if _task_reset or _area.size()!=COLUMNS*ROWS:_reset_state()
	var dirty:Dictionary={}
	for item:Array in _job_items:
		var area:Dictionary=item[0]
		var gain:=_add_record(area,int(item[1]),dirty)
		var kind:=maxi(0,int(item[2]))
		_gain_days.append(int(area.get("day",0)))
		_gain_values.append(gain)
		_gain_categories.append(kind)
		_category_totals[kind]+=gain
	_job_items=[]
	for row:int in dirty:
		var span:Vector2i=dirty[row]
		_refresh_texels(row,span.x,span.y)
	var known:=0.0
	var land:=0.0
	for index in _known:
		known+=_area[index]
		land+=_area[index]*_land[index]
	var by:={}
	for i in CATEGORIES.size():by[CATEGORIES[i]]=_category_totals[i]/maxf(1.0,_surface)
	var chart:=Image.create_from_data(COLUMNS,ROWS,false,Image.FORMAT_RGBA8,_pixels)
	chart.generate_mipmaps()
	_job_result={"image":chart,"stats":{"known_km2":known,"known_fraction":known/_surface,"land_fraction":land/_surface,"sea_fraction":maxf(0.0,known-land)/_surface,
		"surface_km2":_surface,"by_category":by,"days":_gain_days.duplicate(),"gains":_gain_values.duplicate(),"records":_gain_days.size(),"texels":_known.size()}}


## Adds one record (or the part of a trail walked since it was last read) and
## returns the true surface area it added that was not already known.
func _add_record(area:Dictionary,first_point:int,dirty:Dictionary)->float:
	var radius:=maxf(0.0,float(area.get("radius",0.0)))
	if radius<=0.0:return 0.0
	var points:=PackedVector2Array()
	var raw:Array=area.get("points",[])
	if String(area.get("kind","circle"))=="trail" and raw.size()>=2:
		for index in range(maxi(0,first_point),raw.size()):
			var point:Variant=raw[index]
			if point is Dictionary:points.append(Vector2(float(point.get("x",0.0)),float(point.get("z",0.0))))
	else:
		points.append(Vector2(float(area.get("x",0.0)),float(area.get("z",0.0))))
	if points.is_empty():return 0.0
	# Every crossing of this record with a sub-row band, in one flat list of
	# (sub-row, start, end, share of the band's height it covers). A shape
	# whose top or bottom lies inside a band covers only part of it, so an
	# east-west trail edge counts exactly what it covers, not a whole band or
	# nothing. Sorted, the list groups by sub-row and then by start.
	var spans:=PackedVector4Array()
	var segments:=maxi(1,points.size()-1)
	for index in segments:
		var a:=points[index]
		var b:=points[mini(index+1,points.size()-1)]
		var top:=minf(a.y,b.y)-radius
		var bottom:=maxf(a.y,b.y)+radius
		var first:=maxi(0,floori((top+DEPTH_KM*0.5)/SUB_Z))
		var last:=mini(SUBROW_COUNT-1,floori((bottom+DEPTH_KM*0.5)/SUB_Z))
		for s in range(first,last+1):
			var z0:=-DEPTH_KM*0.5+float(s)*SUB_Z
			var from:=maxf(z0,top)
			var to:=minf(z0+SUB_Z,bottom)
			if to-from<=0.000001:continue
			var share:=clampf((to-from)/SUB_Z,0.0,1.0)
			var span:=capsule_span(a,b,radius,subrow_z(s) if share>=0.9999 else (from+to)*0.5)
			span.x=maxf(span.x,-WIDTH_KM*0.5);span.y=minf(span.y,WIDTH_KM*0.5)
			if span.x<span.y:spans.append(Vector4(float(s),span.x,span.y,share))
	spans.sort()
	var gain:=0.0
	var start:=0
	while start<spans.size():
		var s:=int(spans[start].x)
		var local:=PackedVector3Array()
		var end:=start
		while end<spans.size() and int(spans[end].x)==s:
			local.append(Vector3(spans[end].y,spans[end].z,spans[end].w))
			end+=1
		start=end
		var merged:=_merge(_rows.get(s,PackedVector3Array()),local)
		var before:=float(_row_length.get(s,0.0))
		var after:=0.0
		for span in merged:after+=(span.y-span.x)*span.z
		_rows[s]=merged
		_row_length[s]=after
		gain+=(after-before)*_weights[s]
		var row:=s/SUBROWS
		var c0:=clampi(floori((local[0].x+WIDTH_KM*0.5)/TEXEL_X),0,COLUMNS-1)
		var c1:=c0
		for span in local:c1=maxi(c1,clampi(floori((span.y+WIDTH_KM*0.5)/TEXEL_X),0,COLUMNS-1))
		var previous:Vector2i=dirty.get(row,Vector2i(c0,c1))
		dirty[row]=Vector2i(mini(previous.x,c0),maxi(previous.y,c1))
	return gain


## Union of a sub-row's known pieces (start, end, share of the band) with new
## ones; where pieces overlap the larger share stands. `existing` is sorted and
## disjoint; `local` is sorted by start and may overlap itself.
static func _merge(existing:PackedVector3Array,local:PackedVector3Array)->PackedVector3Array:
	var whole:=true
	for piece in local:
		if piece.z<0.9999:whole=false;break
	if whole:
		for piece in existing:
			if piece.z<0.9999:whole=false;break
	if whole:
		# Every piece covers its whole band: a plain union of intervals.
		var out:=PackedVector3Array()
		var i:=0
		var j:=0
		while i<existing.size() or j<local.size():
			var next:Vector3
			if j>=local.size() or (i<existing.size() and existing[i].x<=local[j].x):
				next=existing[i];i+=1
			else:
				next=local[j];j+=1
			var last:=out.size()-1
			if last<0 or next.x>out[last].y:out.append(Vector3(next.x,next.y,1.0))
			elif next.y>out[last].y:out[last]=Vector3(out[last].x,next.y,1.0)
		return out
	# Some pieces cover part of a band: cut at every end and keep the largest
	# share over each cut.
	var pieces:=existing.duplicate()
	pieces.append_array(local)
	pieces.sort()
	var cuts:=PackedFloat64Array()
	for piece in pieces:
		cuts.append(piece.x)
		cuts.append(piece.y)
	cuts.sort()
	var result:=PackedVector3Array()
	var active:=PackedInt32Array()
	var next_piece:=0
	for index in cuts.size()-1:
		var from:=cuts[index]
		var to:=cuts[index+1]
		if to<=from:continue
		while next_piece<pieces.size() and float(pieces[next_piece].x)<=from:
			active.append(next_piece)
			next_piece+=1
		var share:=0.0
		var still:=PackedInt32Array()
		for held in active:
			if float(pieces[held].y)>from:
				still.append(held)
				share=maxf(share,pieces[held].z)
		active=still
		if share<=0.0:continue
		var last:=result.size()-1
		if last>=0 and float(result[last].y)==from and absf(result[last].z-share)<0.000001:
			result[last]=Vector3(result[last].x,to,result[last].z)
		else:
			result.append(Vector3(from,to,share))
	return result


## The share of the band known at x on sub-row s (0 when unknown there).
func _known_on(s:int,x:float)->float:
	var list:PackedVector3Array=_rows.get(s,PackedVector3Array())
	var low:=0
	var high:=list.size()-1
	while low<=high:
		var middle:=(low+high)>>1
		var span:=list[middle]
		if x<span.x:high=middle-1
		elif x>span.y:low=middle+1
		else:return span.z
	return 0.0


## Recomputes the known share, area and samples of texels c0..c1 on one row.
func _refresh_texels(row:int,c0:int,c1:int)->void:
	var count:=c1-c0+1
	var covered:=PackedFloat64Array();covered.resize(count)
	var weighted:=PackedFloat64Array();weighted.resize(count)
	var fallback:=PackedVector2Array();fallback.resize(count)
	var has_fallback:=PackedByteArray();has_fallback.resize(count)
	var left_edge:=-WIDTH_KM*0.5+float(c0)*TEXEL_X
	var right_edge:=-WIDTH_KM*0.5+float(c1+1)*TEXEL_X
	for k in SUBROWS:
		var s:=row*SUBROWS+k
		if not _rows.has(s):continue
		var list:PackedVector3Array=_rows[s]
		var weight:=_weights[s]
		var z:=subrow_z(s)
		for span in list:
			if span.y<=left_edge:continue
			if span.x>=right_edge:break
			var ca:=maxi(c0,floori((span.x+WIDTH_KM*0.5)/TEXEL_X))
			var cb:=mini(c1,floori((span.y+WIDTH_KM*0.5)/TEXEL_X))
			for c in range(ca,cb+1):
				var left:=-WIDTH_KM*0.5+float(c)*TEXEL_X
				var from:=maxf(span.x,left)
				var to:=minf(span.y,left+TEXEL_X)
				if to<=from:continue
				var local_index:=c-c0
				covered[local_index]+=(to-from)*span.z
				weighted[local_index]+=(to-from)*span.z*weight
				# Prefer a fallback sample on a line the ground really crosses.
				if has_fallback[local_index]==0 or (has_fallback[local_index]==1 and span.z>=0.5):
					fallback[local_index]=Vector2((from+to)*0.5,z)
					has_fallback[local_index]=2 if span.z>=0.5 else 1
	var full:=float(SUBROWS)*TEXEL_X
	for local_index in count:
		var share:=clampf(covered[local_index]/full,0.0,1.0)
		if share<=0.0:continue
		var c:=c0+local_index
		var texel:=row*COLUMNS+c
		if _area[texel]<=0.0:_known.append(texel)
		_area[texel]=weighted[local_index]
		# Land, height and greenness only from sample points that are known.
		var left:=-WIDTH_KM*0.5+float(c)*TEXEL_X
		var samples:=0
		var land_samples:=0
		var height_sum:=0.0
		var green_sum:=0.0
		for k:int in SAMPLE_SUBROWS:
			var s:=row*SUBROWS+k
			var z:=subrow_z(s)
			for fraction:float in SAMPLE_COLUMNS:
				var x:=left+TEXEL_X*fraction
				# Half a band or more known means the line itself is known there.
				if _known_on(s,x)<0.5:continue
				var sample:=_sample(Vector2(x,z))
				samples+=1
				height_sum+=sample.x
				green_sum+=sample.y
				if sample.x>LAND_LEVEL:land_samples+=1
		if samples==0:
			var sample:=_sample(fallback[local_index])
			samples=1
			height_sum=sample.x
			green_sum=sample.y
			land_samples=1 if sample.x>LAND_LEVEL else 0
		var land:=float(land_samples)/float(samples)
		_land[texel]=land
		var height_share:=clampf((height_sum/float(samples)-HEIGHT_LOW)/(HEIGHT_HIGH-HEIGHT_LOW),0.0,1.0)
		var green:=clampf(green_sum/float(samples),0.0,1.0)
		var r:=maxi(1,roundi(share*255.0))
		var at:=texel*4
		_pixels[at]=r
		_pixels[at+1]=mini(r,roundi(land*share*255.0))
		_pixels[at+2]=mini(r,roundi(height_share*share*255.0))
		_pixels[at+3]=mini(r,roundi(green*share*255.0))


## Vector2(height, greenness 0..1) at a known point.
func _sample(point:Vector2)->Vector2:
	if height_mode=="raster":return _raster_sample(point)
	if height_mode=="exact":return Vector2(float(_exact_height.call(point)),0.5)
	return Vector2(-1.0,0.5)


func _raster_sample(point:Vector2)->Vector2:
	var gx:=clampf((point.x-_raster_origin.x)/_raster_cell.x,0.0,float(_raster_columns-1)-0.0001)
	var gz:=clampf((point.y-_raster_origin.y)/_raster_cell.y,0.0,float(_raster_rows-1)-0.0001)
	var ix:=floori(gx)
	var iz:=floori(gz)
	var fx:=gx-float(ix)
	var fz:=gz-float(iz)
	var i00:=iz*_raster_columns+ix
	var i10:=i00+1
	var i01:=i00+_raster_columns
	var i11:=i01+1
	var height:=lerpf(lerpf(_raster_heights[i00],_raster_heights[i10],fx),lerpf(_raster_heights[i01],_raster_heights[i11],fx),fz)
	var green:=0.5
	if _raster_colors.size()==_raster_heights.size():
		# The nearest lattice colour: how green the painted land is there.
		var nearest:=(iz+(1 if fz>0.5 else 0))*_raster_columns+ix+(1 if fx>0.5 else 0)
		var color:=Color.hex(_raster_colors[nearest])
		green=clampf(0.5+(color.g-maxf(color.r,color.b))*3.0,0.0,1.0)
	return Vector2(height,green)
