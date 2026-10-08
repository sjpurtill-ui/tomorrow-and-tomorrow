extends Node3D
## Bounded landscape representatives, never homes, sites or routes in the ledger.
## Geometry is in world kilometres. Retained patches share the town's build queue
## implementation and are replaced only when their own visible facts change.
const PLAN = preload("res://scripts/settlement_country_plan.gd")
const PATCHES = preload("res://scripts/settlement_patch_renderer.gd")
const ERA = preload("res://scripts/settlement_country_era.gd")
const INK = preload("res://scripts/settlement_ink.gd")
const SHAPES = preload("res://scripts/settlement_kit_shapes.gd")
const CHART = preload("res://scripts/settlement_country_chart.gd")
const DRAPE = preload("res://scripts/settlement_country_drape.gd")
const EARLY = preload("res://scripts/early_settlement_visual.gd")
const TOWN = preload("res://scripts/organic_town_visual.gd")
const VISUAL_KEYS = preload("res://scripts/settlement_visual_keys.gd")
const GROWTH = preload("res://scripts/settlement_country_growth.gd")
const PLACE_ART = preload("res://scripts/settlement_place_art.gd")
const GROUND_LIFT_KM:=0.0002
const SEED_GROUND_LIFT_KM:=0.000035
var ground_grid:=Vector4.ZERO
var view_center:=Vector2.ZERO
var drape_budget_skips:=0
var height_at:Callable
var land_at:Callable
var visibility_at:Callable
var placement_land_at:Callable
var water_at:Callable
var river_distance_at:Callable
var retained:RefCounted
var last_signature:int = -1
var plan:Dictionary = {}
var request_usec:int = 0
var requests:int = 0
var material:ShaderMaterial
var surface_revision:int=0
var fog_revision:int=0
var last_plan_signature:int=-1
var _land_cache:Dictionary={}
var _physical_land_cache:Dictionary={}
var _height_cache:Dictionary={}
var _visibility_cache:Dictionary={}
var _fog_clipped:=false
# Only one replacement is prepared at a time. Its old complete patch stays
# installed until all bounded clipping and vertex batches have finished.
var _job:Dictionary={}
var _collecting:=false
var _commands:Array[Array]=[]
var _collected_surface:SurfaceTool
var max_prepare_slice_usec:=0
var last_prepare_slice_usec:=0
var max_patch_work_usec:=0
var prepared_patches:=0
var seed_layout_steps:=0
var seed_growth_steps:=0
var _seed_layouts:Dictionary={}
var _pending_seed:Dictionary={}
var _pending_growth:Dictionary={}
var _growth_states:Dictionary={}
var _seed_identity:Array=[]
var _established_seeds:Dictionary={}
var seed_ground_revision:=0
var _seed_ground_keys:Dictionary={}
const MAX_PREPARE_STEPS:=512

func invalidate(drape:bool=true)->void:
	# Rendered terrain and discovery masks can change without a simulation day.
	if drape:surface_revision+=1
	else:fog_revision+=1
	last_signature=-1

func configure(height:Callable,land:Callable=Callable(),revealed:Callable=Callable(),physical_land:Callable=Callable())->void:
	height_at=height;land_at=land;visibility_at=revealed;placement_land_at=physical_land if physical_land.is_valid() else land
	if retained==null:retained=PATCHES.new(self)
	if material==null:
		material=ShaderMaterial.new()
		material.shader=preload("res://scripts/shaders/settlement_country_ground.gdshader")

func request(snapshot:Dictionary,style:Dictionary={})->void:
	var began:=Time.get_ticks_usec()
	var plan_key:=PLAN.signature(snapshot)
	var key:=hash([plan_key,style,view_center])
	if key==last_signature:return
	var identity:Array=[String(snapshot.get("owner","player")),int(snapshot.get("seed",0)),snapshot.get("origin",Vector2.ZERO)]
	if identity!=_seed_identity or not bool(snapshot.get("founded",true)):
		_seed_identity=identity
		_seed_layouts.clear();_growth_states.clear();_established_seeds.clear()
		if not _seed_ground_keys.is_empty():seed_ground_revision+=1
		_seed_ground_keys.clear()
	else:
		# Sampling head-count is not an abandonment event. Remember only seeds
		# whose physical patch has actually installed, never queued candidates.
		for record:Dictionary in plan.get("homesteads",[]):
			if not record.has("settlement_growth"):continue
			# Named places have real abandonment and a four-ruin retention cap.
			# Only anonymous display seeds need this head-count continuity fallback.
			if record.has("place") or String(record.get("id","")).begins_with("place:"):continue
			var id:=String(record.id)
			var patch_id:="homesteads:"+id
			if not retained.installed.has(patch_id):continue
			var node:Node3D=retained.installed[patch_id].node
			if String(node.get_meta("country_seed_id",""))!=id:continue
			if _established_seeds.has(id) or _established_seeds.size()<GROWTH.MAX_SEEDS:
				_established_seeds[id]=record.duplicate(true)
	last_signature=key;requests+=1
	if plan_key!=last_plan_signature:
		plan=PLAN.build(snapshot);last_plan_signature=plan_key
		if bool(snapshot.get("founded",true)):
			var active_seeds:Dictionary={}
			for record:Dictionary in plan.get("homesteads",[]):
				if record.has("settlement_growth") or record.has("settlement_plots"):active_seeds[String(record.id)]=true
			for id:String in _established_seeds:
				if active_seeds.has(id):continue
				if id.begins_with("place:") or active_seeds.size()>=GROWTH.MAX_SEEDS:continue
				var record:Dictionary=_established_seeds[id].duplicate(true)
				# Real root growth may absorb individual roofs, but cannot reroll
				# the other inherited parcels of this already established seed.
				record.settlement_growth.obstacles=PLAN.seed_obstacles(snapshot.get("root_fabric",{}),record.offset)
				record.geometry_signature=hash(record.settlement_growth)
				plan.homesteads.append(record)
				active_seeds[id]=true
			plan.homesteads.sort_custom(PLAN._nearer)
	var entries:Array[Dictionary]=[]
	var seed_ids:Dictionary={}
	var anchors:Array[Vector2]=[Vector2(snapshot.get("origin",Vector2.ZERO))]
	var country_appearance:Dictionary=plan.get("country_appearance",{})
	if country_appearance.is_empty():country_appearance=ERA.capture(snapshot.get("knowledge",[]),snapshot.get("built_fabric",{}))
	var context:Dictionary={"origin":snapshot.get("origin",Vector2.ZERO),"road_tier":snapshot.get("road_tier",0),"country_appearance":ERA.render_profile(country_appearance),"style":style.duplicate(true)}
	for kind:String in ["homesteads","herders","sites"]:
		for source:Dictionary in plan.get(kind,[]):
			var record:=source.duplicate(true)
			record["group"]=kind
			var point:Vector2=record.position
			if record.has("settlement_plots") or record.has("settlement_growth"):seed_ids[String(record.id)]=true
			var nearest:Vector2=anchors[0]
			var distance:=point.distance_squared_to(nearest)
			for anchor:Vector2 in anchors:
				var test:=point.distance_squared_to(anchor)
				if test<distance:nearest=anchor;distance=test
			if kind=="herders":nearest=point.move_toward(anchors[0],minf(2.0,point.distance_to(anchors[0])))
			if record.has("place"):nearest=Vector2(record.get("track_from",anchors[0]))
			# Long work hauls end at a local farmstead. These are worn tracks,
			# never new supply lines or another named settlement.
			record["track_from"]=nearest
			if kind=="homesteads":anchors.append(point)
			var id:="%s:%s" % [kind,str(record.get("id",hash(point)))]
			# Discovery refreshes change only records whose visibility changes.
			# Full terrain sampling is kept inside the deferred bounded builder.
			var admitted:=not visibility_at.is_valid() or bool(visibility_at.call(point))
			var start_seen:=not visibility_at.is_valid() or bool(visibility_at.call(nearest))
			var clipped_revision:=0
			if retained.installed.has(id) and bool(retained.installed[id].node.get_meta("fog_clipped",false)):clipped_revision=fog_revision
			if not _job.is_empty() and _job.key==id and _fog_clipped:clipped_revision=fog_revision
			var appearance:=[point,record.get("category",""),record.get("age",""),record.get("resource",""),record.get("field_radius_km",0.0),record.get("radius_km",0.0),record.get("buildings",2),record.get("geometry_signature",record.get("settlement_growth",{})),nearest,admitted,start_seen,clipped_revision]
			entries.append({"key":id,"signature":hash([appearance,context,surface_revision]),"priority":point.distance_squared_to(view_center),"build":_build_patch.bind(record,context)})
	# Active and remembered seeds share one fixed24-slot budget. Keep inactive
	# layout history within spare slots; changing settlement identity clears all.
	var remembered:Array=_seed_layouts.keys()
	for id:String in _growth_states:
		if id not in remembered:remembered.append(id)
	var spare:=maxi(0,GROWTH.MAX_SEEDS-seed_ids.size())
	for id:String in remembered:
		if seed_ids.has(id):continue
		if id.begins_with("place:"):
			_seed_layouts.erase(id);_growth_states.erase(id)
			continue
		if spare>0:spare-=1
		else:_seed_layouts.erase(id);_growth_states.erase(id)
	for id:String in _seed_ground_keys.keys():
		if not seed_ids.has(id):_seed_ground_keys.erase(id);seed_ground_revision+=1
	retained.request(entries)
	request_usec=Time.get_ticks_usec()-began

func process_jobs(budget_usec:int=2000,max_jobs:int=2)->void:
	if retained==null:return
	retained.last_jobs=0
	if max_jobs<=0:return
	var began:=Time.get_ticks_usec()
	var completed:=0
	var steps:=0
	while completed<max_jobs and steps<MAX_PREPARE_STEPS:
		if steps>0 and Time.get_ticks_usec()-began>=maxi(1,budget_usec):break
		steps+=1
		if not _job.is_empty() and (not retained.desired.has(_job.key) or retained.desired[_job.key].signature!=_job.signature or (not retained.pending.is_empty() and retained.pending[0]!=_job.key)):
			_discard_job()
		if _job.is_empty():
			if retained.pending.is_empty():break
			_start_job(retained.pending[0])
			continue
		var started:=Time.get_ticks_usec()
		if _advance_job():
			_job.work_usec+=Time.get_ticks_usec()-started
			max_patch_work_usec=maxi(max_patch_work_usec,int(_job.work_usec))
			var key:String=_job.key
			var source:Dictionary=retained.desired[key]
			var original:Callable=source.build
			source.build=_install_prepared.bind(_job.node)
			retained.pending.erase(key);retained.pending.push_front(key)
			retained.process(1,1)
			source.build=original
			_job={};completed+=1;prepared_patches+=1
		else:_job.work_usec+=Time.get_ticks_usec()-started
	retained.last_jobs=completed
	last_prepare_slice_usec=Time.get_ticks_usec()-began
	max_prepare_slice_usec=maxi(max_prepare_slice_usec,last_prepare_slice_usec)
	retained.last_slice_usec=last_prepare_slice_usec

func _start_job(key:String)->void:
	var began:=Time.get_ticks_usec()
	var source:Dictionary=retained.desired[key]
	var staging:=Node3D.new()
	_commands=[];_collected_surface=null;_pending_seed={};_pending_growth={};_collecting=true
	(source.build as Callable).call(staging)
	_collecting=false
	_commands.reverse()
	_job={"key":key,"signature":source.signature,"node":staging,"surface":_collected_surface,"commands":_commands,"pieces":[],"piece_index":0,"lift":GROUND_LIFT_KM,"center_check":false,"seed":_pending_seed,"growth":_pending_growth,"work_usec":Time.get_ticks_usec()-began}
	_commands=[];_collected_surface=null;_pending_seed={};_pending_growth={}

func _advance_job()->bool:
	var growth:Dictionary=_job.get("growth",{})
	if not growth.is_empty():
		seed_growth_steps+=1
		if not GROWTH.advance(growth.state,_placement_land,height_at,river_distance_at):return false
		var work:=_begin_seed_layout(_grown_record(growth.record,growth.state))
		work["growth_state"]=growth.state
		_collecting=true;_commands=[]
		_draw_seed_ground(_job.surface,work)
		_collecting=false
		_commands.reverse();(_job.commands as Array).append_array(_commands);_commands=[]
		_job.seed=work;_job.growth={}
		return false
	var seed_work:Dictionary=_job.get("seed",{})
	if not seed_work.is_empty():
		if seed_work.has("place_track_job"):
			if not PLACE_ART.advance_track(seed_work.place_track_job,_placement_land):return false
			_collecting=true;_commands=[]
			_draw_place_track(_job.surface,seed_work)
			_collecting=false
			_commands.reverse();(_job.commands as Array).append_array(_commands);_commands=[]
			return false
		if not (seed_work.pending as Array).is_empty():
			_advance_seed_layout(seed_work)
			return false
		_finish_seed(_job.node,seed_work)
		_job.seed={}
		return false
	var pieces:Array=_job.pieces
	if int(_job.piece_index)<pieces.size():
		var triangle:Array=pieces[int(_job.piece_index)]
		_job.piece_index+=1
		_emit_triangle(_job.surface,triangle,float(_job.lift),bool(_job.center_check))
		return false
	var commands:Array=_job.commands
	if not commands.is_empty():
		var command:Array=commands.pop_back()
		var work:=_triangle_work(command)
		_job.pieces=work.pieces;_job.piece_index=0
		_job.lift=command[6];_job.center_check=work.center_check
		var children:Array=work.children
		for index in range(children.size()-1,-1,-1):commands.append(children[index])
		return false
	_job.node.set_meta("fog_clipped",_fog_clipped)
	if _job.surface!=null:_finish_surface(_job.node,_job.surface)
	return true

func _install_prepared(parent:Node3D,staging:Node3D)->void:
	if staging.has_meta("country_seed_id"):
		var id:=String(staging.get_meta("country_seed_id"))
		var key:int=staging.get_meta("country_seed_geometry")
		if int(_seed_ground_keys.get(id,-1))!=key:seed_ground_revision+=1
		_seed_ground_keys[id]=key
	for key:StringName in staging.get_meta_list():parent.set_meta(key,staging.get_meta(key))
	for child:Node in staging.get_children():
		staging.remove_child(child);parent.add_child(child)
	staging.free()

func _discard_job()->void:
	if not _job.is_empty() and is_instance_valid(_job.node):_job.node.free()
	_job={}

func _notification(what:int)->void:
	if what==NOTIFICATION_PREDELETE:_discard_job()

func stats()->Dictionary:
	var result:Dictionary=retained.stats() if retained!=null else {}
	result["requests"]=requests;result["request_usec"]=request_usec
	result["homesteads"]=plan.get("homesteads",[]).size()
	result["herders"]=plan.get("herders",[]).size()
	result["sites"]=plan.get("sites",[]).size()
	result["drape_budget_skips"]=drape_budget_skips
	result["preparing"]=_job.get("key","")
	result["last_prepare_slice_usec"]=last_prepare_slice_usec
	result["max_prepare_slice_usec"]=max_prepare_slice_usec
	result["max_patch_work_usec"]=max_patch_work_usec
	result["prepared_patches"]=prepared_patches
	result["seed_layout_steps"]=seed_layout_steps
	result["seed_growth_steps"]=seed_growth_steps
	result["seed_layouts"]=_seed_layouts.size()
	result["seed_ground_revision"]=seed_ground_revision
	return result

## Actual installed parcels for the shared canopy mask. The manager can retain
## its bounded clearing list until seed_ground_revision changes.
func seed_ground_records()->Array[Dictionary]:
	var records:Array[Dictionary]=[]
	if retained==null:return records
	for key:String in retained.installed:
		if not retained.desired.has(key):continue
		var node:Node3D=retained.installed[key].node
		if not node.has_meta("country_seed_id"):continue
		records.append({"id":String(node.get_meta("country_seed_id")),"origin":node.get_meta("country_seed_origin"),
			"plots":node.get_meta("country_seed_plots"),"routes":node.get_meta("country_seed_routes"),"plan":node.get_meta("country_seed_plan")})
	return records

func _valid(point:Vector2)->bool:
	if not _visibility_cache.has(point):_visibility_cache[point]=not visibility_at.is_valid() or bool(visibility_at.call(point))
	if not bool(_visibility_cache[point]):_fog_clipped=true
	if not _land_cache.has(point):_land_cache[point]=not land_at.is_valid() or bool(land_at.call(point))
	return bool(_land_cache[point])

func _point(point:Vector2,lift:float=GROUND_LIFT_KM)->Vector3:
	if not _height_cache.has(point):_height_cache[point]=float(height_at.call(point))
	return Vector3(point.x,float(_height_cache[point])+lift,point.y)

func _tri(surface:SurfaceTool,a:Vector2,b:Vector2,c:Vector2,color:Color,lift:float=GROUND_LIFT_KM)->void:
	_graded_tri(surface,a,b,c,color,color,color,lift)

func _graded_tri(surface:SurfaceTool,a:Vector2,b:Vector2,c:Vector2,ca:Color,cb:Color,cc:Color,lift:float=GROUND_LIFT_KM,depth:int=0)->void:
	if not _ground_rect_visible(a.min(b).min(c),a.max(b).max(c)):return
	var command:Array=[a,b,c,ca,cb,cc,lift,depth]
	if _collecting:
		_commands.append(command)
		return
	var work:=_triangle_work(command)
	for child:Array in work.children:
		_graded_tri(surface,child[0],child[1],child[2],child[3],child[4],child[5],child[6],child[7])
	for triangle:Array in work.pieces:_emit_triangle(surface,triangle,lift,bool(work.center_check))

func _triangle_work(command:Array)->Dictionary:
	var a:Vector2=command[0];var b:Vector2=command[1];var c:Vector2=command[2]
	var ca:Color=command[3];var cb:Color=command[4];var cc:Color=command[5]
	var lift:float=command[6];var depth:int=command[7]
	var work:={"pieces":[],"children":[],"center_check":false}
	if not _ground_rect_visible(a.min(b).min(c),a.max(b).max(c)):return work
	if ground_grid.w>=2.0 and ground_grid.z>0.0:
		var clipped:=DRAPE.split_triangle_result(a,b,c,ca,cb,cc,ground_grid)
		work.pieces=clipped.triangles
		if clipped.status=="budget_exceeded":
			# These children are queued, never recursively completed in one frame.
			if depth<6:
				var ab:=a.distance_squared_to(b);var bc:=b.distance_squared_to(c);var ac:=a.distance_squared_to(c)
				if ab>=bc and ab>=ac:
					var middle:=(a+b)*0.5;var color:=ca.lerp(cb,0.5)
					work.children=[[a,middle,c,ca,color,cc,lift,depth+1],[middle,b,c,color,cb,cc,lift,depth+1]]
				elif bc>=ac:
					var middle:=(b+c)*0.5;var color:=cb.lerp(cc,0.5)
					work.children=[[a,b,middle,ca,cb,color,lift,depth+1],[a,middle,c,ca,color,cc,lift,depth+1]]
				else:
					var middle:=(a+c)*0.5;var color:=ca.lerp(cc,0.5)
					work.children=[[a,b,middle,ca,cb,color,lift,depth+1],[middle,b,c,color,cb,cc,lift,depth+1]]
			else:drape_budget_skips+=1
		return work
	if depth<2 and maxf(a.distance_squared_to(b),maxf(b.distance_squared_to(c),c.distance_squared_to(a)))>0.16:
		var ab:=(a+b)*0.5;var bc:=(b+c)*0.5;var ac:=(a+c)*0.5
		var cab:=ca.lerp(cb,0.5);var cbc:=cb.lerp(cc,0.5);var cac:=ca.lerp(cc,0.5)
		work.children=[[a,ab,ac,ca,cab,cac,lift,depth+1],[ab,b,bc,cab,cb,cbc,lift,depth+1],[ac,bc,c,cac,cbc,cc,lift,depth+1],[ab,bc,ac,cab,cbc,cac,lift,depth+1]]
		return work
	work.pieces=[[{"point":a,"color":ca},{"point":b,"color":cb},{"point":c,"color":cc}]]
	work.center_check=true
	return work

func _emit_triangle(surface:SurfaceTool,triangle:Array,lift:float,center_check:bool)->void:
	var a:Vector2=triangle[0].point;var b:Vector2=triangle[1].point;var c:Vector2=triangle[2].point
	if not _valid(a) or not _valid(b) or not _valid(c):return
	if center_check and not _valid(a+((b-a)+(c-a))/3.0):return
	for vertex:Dictionary in triangle:
		surface.set_color((vertex.color as Color).srgb_to_linear());surface.set_normal(Vector3.UP);surface.add_vertex(_point(vertex.point,lift))

func _ground_rect_visible(low:Vector2,high:Vector2)->bool:
	if ground_grid.w<2.0 or ground_grid.z<=0.0:return true
	var corner:=Vector2(ground_grid.x,ground_grid.y)-Vector2.ONE*ground_grid.z*0.5
	var end:=corner+Vector2.ONE*ground_grid.z
	return high.x>=corner.x and high.y>=corner.y and low.x<=end.x and low.y<=end.y

func _wash(surface:SurfaceTool,center:Vector2,radius:float,color:Color,seed_value:int,stretch:float=1.0)->void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var perimeter:Array[Vector2]=[]
	var turn:=rng.randf()*TAU
	for i in 7:
		var offset:=Vector2.from_angle(turn+TAU*float(i)/7.0)*radius*rng.randf_range(0.52,1.16)
		offset.x*=stretch;perimeter.append(center+offset)
	for i in perimeter.size():
		var a:Vector2=perimeter[i];var b:Vector2=perimeter[(i+1)%perimeter.size()]
		var edge:=color;edge.a=0.0
		_graded_tri(surface,center,a,b,color,edge,edge)

func _field(surface:SurfaceTool,field:Dictionary,color:Color)->void:
	var center:Vector2=field.center
	var along:=Vector2.from_angle(float(field.angle))*float(field.half_length_km)
	var across:=along.normalized().orthogonal()*float(field.half_width_km)
	var corners:=[center-along-across,center+along*0.94-across*0.92,center+along+across*0.92,center-along*0.91+across]
	# Separate narrow strips, not four overlapping kilometre-wide washes.
	# Painted loam and stubble remain legible while the irregular rim softens.
	for row in 10:
		var start:=float(row)/10.0;var finish:=float(row+1)/10.0
		var a:Vector2=corners[0].lerp(corners[3],start)
		var b:Vector2=corners[1].lerp(corners[2],start)
		var c:Vector2=corners[1].lerp(corners[2],finish)
		var d:Vector2=corners[0].lerp(corners[3],finish)
		var ink:=color.lerp(Color("#705b3e"),0.22 if row%2==0 else 0.0)
		ink.a=0.83 if row%2==0 else 0.69
		_tri(surface,a,b,c,ink);_tri(surface,a,c,d,ink)
	for i in 4:_ribbon(surface,corners[i],corners[(i+1)%4],0.0011,Color(0.38,0.36,0.22,0.44))

func _ribbon(surface:SurfaceTool,start:Vector2,finish:Vector2,width:float,color:Color,lift:float=GROUND_LIFT_KM)->void:
	var side:=(finish-start).normalized().orthogonal()*width*0.5
	_tri(surface,start-side,start+side,finish+side,color,lift)
	_tri(surface,start-side,finish+side,finish-side,color,lift)

func _track(surface:SurfaceTool,start:Vector2,finish:Vector2,seed_value:int,tier:int)->void:
	var length:=start.distance_to(finish)
	if length<0.01:return
	var margin:=Vector2.ONE*(0.07*minf(length,10.0)+0.025*minf(length,3.0)+0.004)
	if not _ground_rect_visible(start.min(finish)-margin,start.max(finish)+margin):return
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var cross:=(finish-start).normalized().orthogonal()
	var pieces:=clampi(ceili(length/0.12),4,256)
	var previous:=start
	var bend:=rng.randf_range(-0.07,0.07)*minf(length,10.0)
	for i in range(1,pieces+1):
		var t:=float(i)/float(pieces)
		var point:=start.lerp(finish,t)+cross*sin(t*PI)*(bend+sin(t*PI*3.0+float(seed_value%17))*minf(length,3.0)*0.025)
		var width:=lerpf(0.006 if tier==2 else 0.003,0.0012,t)
		var side:=(point-previous).normalized().orthogonal()*width*0.5
		var color:=Color("#978465") if tier<2 else Color("#a3987c")
		color.a=0.67
		_tri(surface,previous-side,previous+side,point+side,color)
		_tri(surface,previous-side,point+side,point-side,color)
		previous=point

func _build_patch(parent:Node3D,record:Dictionary,context:Dictionary)->void:
	_land_cache.clear();_physical_land_cache.clear();_height_cache.clear();_visibility_cache.clear()
	_fog_clipped=false
	var at:Vector2=record.position
	var is_seed:=record.has("settlement_plots") or record.has("settlement_growth")
	if not _valid(at) and not is_seed:
		parent.set_meta("fog_clipped",_fog_clipped)
		return
	var seed_value:=absi(hash(record.get("id",at)))
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var group:=String(record.group)
	# Inhabited expansion is read through roofs and yards, not field-line glyphs.
	var chart:Node3D=null if is_seed or String(record.get("kind",""))=="cluster" else CHART.create(record,height_at)
	if chart!=null:parent.add_child(chart)
	if group=="sites":
		_draw_site(surface,record,seed_value)
	elif is_seed:
		if record.has("settlement_growth"):
			var state:=GROWTH.begin(record,_growth_states.get(String(record.id),{}))
			if _collecting:_pending_growth={"record":record,"state":state}
			else:
				seed_growth_steps+=1
				while not GROWTH.advance(state,_placement_land,height_at,river_distance_at):seed_growth_steps+=1
				var work:=_begin_seed_layout(_grown_record(record,state));work["growth_state"]=state
				_draw_seed_ground(surface,work)
				while not (work.pending as Array).is_empty():_advance_seed_layout(work)
				_finish_seed(parent,work)
		else:
			var work:=_begin_seed_layout(record)
			_draw_seed_ground(surface,work)
			if _collecting:_pending_seed=work
			else:
				while not (work.pending as Array).is_empty():_advance_seed_layout(work)
				_finish_seed(parent,work)
	else:
		var sparse:=group=="herders"
		var layout:=PLAN.homestead_layout(record)
		parent.set_meta("country_layout",layout)
		_wash(surface,at,float(layout.yard_radius_km),Color(0.58,0.49,0.34,0.86),seed_value)
		for field:Dictionary in layout.fields:
			var color:=Color("#b09a67").lerp(Color("#7d8150"),rng.randf()*0.65)
			_field(surface,field,color)
			var to_field:Vector2=(Vector2(field.center)-at).normalized()
			var entry:Vector2=Vector2(field.center)-to_field*float(field.half_width_km)
			_track(surface,at+to_field*float(layout.yard_radius_km)*0.78,entry,seed_value+17,0)
		_add_homes(parent,at,1 if sparse else int(record.get("buildings",2)),seed_value,context)
		if bool(layout.get("is_cluster",false)):
			# Short worn lanes belong to the compound; avoid survey-like spokes
			# stretching across the surrounding landscape.
			for home:Vector2 in parent.get_meta("country_home_positions",[]):
				var toward:Vector2=at.move_toward(home,0.010)
				_track(surface,toward,home.move_toward(at,0.005),seed_value+int(home.x*1000.0),0)
	# Exposed rock exhausted long ago has no new busy track; living woods and
	# staffed workplaces retain access. Thin ground-coloured paths disappear
	# naturally at realm zoom, rather than becoming chart-wide spokes.
	if not is_seed and (group!="sites" or String(record.get("category",""))!="depleted"):
		var finish:=at
		if group!="sites":finish=at.move_toward(Vector2(record.track_from),float(PLAN.homestead_layout(record).yard_radius_km)*0.78)
		_track(surface,Vector2(record.track_from),finish,seed_value,int(record.get("road_tier",context.road_tier)))
	parent.set_meta("fog_clipped",_fog_clipped)
	if _collecting:
		_collected_surface=surface
		return
	_finish_surface(parent,surface)

## Every organic seed uses the root settlement's parcel/frontage solver. Saved
## sites belong only to these bounded display copies, never to the engine ledger.
func _grown_record(record:Dictionary,state:Dictionary)->Dictionary:
	var grown:=record.duplicate(false)
	grown["settlement_plots"]=state.plots;grown["settlement_routes"]=state.routes
	if record.has("place") and Vector2(record.place.get("facing",Vector2.ZERO))==Vector2.ZERO and Vector2(state.get("facing",Vector2.ZERO))!=Vector2.ZERO:
		grown["place"]=(record.place as Dictionary).duplicate(true)
		grown.place["facing"]=state.facing
	return grown

func _placement_land(world:Vector2)->bool:
	if not _physical_land_cache.has(world):_physical_land_cache[world]=not placement_land_at.is_valid() or bool(placement_land_at.call(world))
	return bool(_physical_land_cache[world])

func _begin_seed_layout(record:Dictionary)->Dictionary:
	var id:=String(record.id)
	var plots:Array[Dictionary]=[];plots.assign((record.settlement_plots as Array).duplicate(true))
	var routes:Array[Dictionary]=[];routes.assign((record.get("settlement_routes",[]) as Array).duplicate(true))
	var inputs:=VISUAL_KEYS.layout_inputs(plots,routes)
	var cached:Dictionary=_seed_layouts.get(id,{})
	var saved:Dictionary={}
	for plot:Dictionary in cached.get("plots",[]):saved[int(plot.id)]=plot
	for plot:Dictionary in plots:
		if not saved.has(int(plot.id)):continue
		var prior:Dictionary=saved[int(plot.id)]
		if prior.has("visual_building_sites"):
			plot["visual_building_sites"]=(prior.visual_building_sites as Array).duplicate(true)
			plot["visual_sites_form"]=prior.get("visual_sites_form","")
	var pending:Array[int]=[]
	for plot_id:int in inputs:
		if inputs[plot_id]!=(cached.get("inputs",{}) as Dictionary).get(plot_id,-1):pending.append(plot_id)
	pending.sort()
	var prior_plan:Dictionary=cached.get("plan",{"buildings":[],"replaced":{}})
	return {"id":id,"origin":Vector2(record.position),"plots":plots,"routes":routes,
		"place":record.get("place",{}),"track_from":record.get("track_from",record.position),"road_tier":record.get("road_tier",0),
		"ownership":record.get("settlement_growth",{}),"inputs":inputs,"pending":pending,"plan":VISUAL_KEYS.refresh_plan(prior_plan,plots)}

func _seed_visible(local:Vector2,origin:Vector2,ownership:Dictionary={})->bool:
	var world:=origin+local
	return GROWTH.owns(ownership,local) and _valid(world) and bool(_visibility_cache.get(world,true))

func _seed_footprint_unoccupied(footprint:PackedVector2Array,ownership:Dictionary)->bool:
	# The actual town can absorb a saved representative without relocating its
	# neighbours. Polygon intersection also catches a small new claim entirely
	# inside a footprint, where centre/corner terrain samples could miss it.
	if footprint.size()<3:return true
	var bounds:=TOWN.bounds(footprint)
	for claim:Dictionary in ownership.get("obstacles",[]):
		var polygon:PackedVector2Array=claim.get("polygon",PackedVector2Array())
		if polygon.size()<3 or not bounds.intersects(TOWN.bounds(polygon)):continue
		if not Geometry2D.intersect_polygons(footprint,polygon).is_empty():return false
	return true

func _advance_seed_layout(work:Dictionary)->void:
	var plot_id:int=work.pending.pop_front()
	# Fog cannot change parcel placement or reserve a different future house.
	var land:=func(point:Vector2)->bool:return GROWTH.owns(work.ownership,point) and _placement_land(Vector2(work.origin)+point)
	work.plan=EARLY.layout(work.plots,work.routes,land,{plot_id:true})
	# The same reserved-site mechanism as the root renderer, on display copies.
	EARLY.remember_layout(work.plan,work.plots)
	seed_layout_steps+=1

func _finish_seed(parent:Node3D,work:Dictionary)->void:
	_seed_layouts[String(work.id)]={"inputs":work.inputs,"plots":work.plots,"plan":work.plan}
	if work.has("growth_state"):_growth_states[String(work.id)]=work.growth_state
	var visible:Array=[]
	var positions:Array[Vector2]=[]
	for building:Dictionary in work.plan.buildings:
		var plot:Dictionary=building.plot
		if String(plot.get("status","active")) in ["ruin","reclaimed"] or float((plot.get("damage",{}) as Dictionary).get("structural",0.0))>0.65:continue
		var footprint:PackedVector2Array=building.get("footprint",PackedVector2Array())
		var clear:=_seed_visible(Vector2(building.position),work.origin,work.ownership) and _seed_footprint_unoccupied(footprint,work.ownership)
		for index in footprint.size():
			if not _seed_visible(footprint[index],work.origin,work.ownership) or not _seed_visible(footprint[index].lerp(footprint[(index+1)%footprint.size()],0.5),work.origin,work.ownership):clear=false;break
		if not clear:continue
		visible.append(building);positions.append(Vector2(work.origin)+Vector2(building.position))
	var shown:={"buildings":visible,"replaced":work.plan.replaced}
	var origin:Vector2=work.origin
	var place:Dictionary=work.get("place",{})
	var occupied:=PLACE_ART.render_damage(parent,shown,place,origin,func(point:Vector2)->float:return _point(point,0.0).y)
	EARLY.render(occupied,Vector3(origin.x,0.0,origin.y),func(x:float,z:float)->float:return _point(Vector2(x,z),0.0).y,parent)
	if not place.is_empty():
		positions.clear()
		for building:Dictionary in occupied.buildings:positions.append(origin+Vector2(building.position))
	parent.set_meta("country_home_count",occupied.buildings.size())
	parent.set_meta("country_home_positions",positions)
	parent.set_meta("country_seed_plan",occupied)
	parent.set_meta("country_seed_plots",work.plots)
	parent.set_meta("country_seed_routes",work.routes)
	parent.set_meta("country_seed_id",work.id)
	parent.set_meta("country_seed_origin",work.origin)
	parent.set_meta("country_seed_geometry",hash([work.origin,work.inputs]))
	if not place.is_empty():
		for key:String in ["id","name","kind","status","trend","flooded"]:parent.set_meta("country_place_"+key,place.get(key,""))
		parent.set_meta("country_place_fade",PLACE_ART.ruin_fade(place))
		parent.set_meta("place_track_points",work.get("place_track_points",PackedVector2Array()))
		if _seed_visible(Vector2.ZERO,origin):
			parent.add_child(PLACE_ART.label(place,origin,func(point:Vector2)->float:return _point(point,0.0).y))
		PLACE_ART.render_props(parent,work.get("place_details",{}),func(point:Vector2)->float:return _point(point,0.0).y,
			func(point:Vector2)->bool:return _valid(point) and bool(_visibility_cache.get(point,true)),visibility_at)

func _draw_seed_ground(surface:SurfaceTool,work:Dictionary)->void:
	var origin:Vector2=work.origin
	for plot:Dictionary in work.plots:
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		if polygon.size()<3 or String(plot.get("land_use","")) in ["water","vacant","waste"]:continue
		var triangles:=Geometry2D.triangulate_polygon(polygon)
		var field:=String(plot.get("land_use","")) in ["field","pasture"]
		var color:=Color(0.55,0.50,0.32,0.43) if field else Color(0.58,0.49,0.34,0.26)
		for index in range(0,triangles.size(),3):
			_tri(surface,origin+polygon[triangles[index]],origin+polygon[triangles[index+1]],origin+polygon[triangles[index+2]],color,SEED_GROUND_LIFT_KM)
	for route:Dictionary in work.routes:
		if not bool(route.get("active",true)):continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		var width:=TOWN.route_half_width(route)*2.0
		for index in range(1,points.size()):
			_ribbon(surface,origin+points[index-1],origin+points[index],width,Color(0.58,0.50,0.38,0.62),SEED_GROUND_LIFT_KM)
	var place:Dictionary=work.get("place",{})
	if place.is_empty():return
	var detail:=PLACE_ART.details(work,_placement_land,water_at)
	work["place_details"]=detail
	for wash:Dictionary in detail.get("washes",[]):_wash(surface,wash.position,wash.radius,wash.color,hash([work.id,wash.position]))
	for field:Dictionary in detail.get("fields",[]):_field(surface,field,field.color)
	for line:Dictionary in detail.get("lines",[]):_ribbon(surface,line.start,line.finish,line.width,Color(0.58,0.50,0.38,0.62))
	work["place_track_job"]=PLACE_ART.begin_track(Vector2(work.track_from),origin,place)
	if not _collecting:
		while not PLACE_ART.advance_track(work.place_track_job,_placement_land):pass
		_draw_place_track(surface,work)

func _draw_place_track(surface:SurfaceTool,work:Dictionary)->void:
	var track:PackedVector2Array=work.place_track_job.points
	work["place_track_points"]=track;work.erase("place_track_job")
	var place:Dictionary=work.place
	var tier:=int(work.get("road_tier",0))
	var width:=0.006 if tier>=2 else (0.0026 if tier==1 else 0.0012)
	var tint:=Color(0.58,0.51,0.40,0.52) if tier<2 else Color(0.66,0.62,0.52,0.64)
	if String(place.get("status","living"))=="ruin":tint.a*=PLACE_ART.ruin_fade(place)*0.5
	for index in range(1,track.size()):_ribbon(surface,track[index-1],track[index],width,tint)

func _finish_surface(parent:Node3D,surface:SurfaceTool)->void:
	var arrays:=surface.commit_to_arrays()
	if arrays.is_empty() or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:return
	if (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():return
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node:=MeshInstance3D.new();node.name="WorkedEarth";node.mesh=mesh
	node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func _draw_site(surface:SurfaceTool,record:Dictionary,seed_value:int)->void:
	var at:Vector2=record.position
	var category:=String(record.get("category","active"))
	var age:=String(record.get("age",""))
	var resource:=String(record.get("resource",""))
	var radius:=float(record.get("radius_km",record.get("field_radius_km",0.48)))
	var extent:=Vector2.ONE*(1.18+radius*1.4)
	if not _ground_rect_visible(at-extent,at+extent):return
	var color:=Color("#a89468")
	if "wood" in age or resource=="Timber":color=Color("#8c9b65") if category=="regrowing" else Color("#8c7958")
	elif "quarry" in age or resource=="Stone":color=Color("#aaa18d") if category=="depleted" else Color("#b6a58b")
	elif resource in ["Plant Fiber","Fiber Plants"]:color=Color("#989464")
	color.a=0.68 if category=="depleted" else 0.40
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+41
	# Marks stay inside the real 3km catchment. Distinct irregular cuts and
	# strips communicate work history instead of one almost invisible haze.
	var spread:=1.18 if float(record.get("tile_area_km2",0.0))>0.0 else radius*0.7
	for i in 7:
		var patch:=at+Vector2.from_angle(rng.randf()*TAU)*spread*rng.randf_range(0.10,0.82)
		# The ledger bounds the catchment, not a solid excavated surface. Keep
		# representative scars local instead of tessellating square kilometres
		# of faint paint whenever the camera moves in for a house.
		var size:=minf(radius*rng.randf_range(0.20,0.37),0.060)
		var tint:=color.darkened(rng.randf_range(0.02,0.16));tint.a=0.68
		if category=="regrowing":tint=Color(0.53,0.59,0.35,0.66)
		_wash(surface,patch,size,tint,seed_value+71+i,1.15)
		if "quarry" in age or resource=="Stone":
			# Small exposed rubble patches, in metres. A 3km catchment is not a
			# quarry face: scaling benches by it produced 300m dark bars.
			for chip in 3:
				var place:=patch+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(0.005,0.025)
				_wash(surface,place,rng.randf_range(0.002,0.006),Color(0.59,0.57,0.50,0.45),seed_value+201+i*3+chip)

func _add_homes(parent:Node3D,at:Vector2,count:int,seed_value:int,context:Dictionary)->void:
	var style:Dictionary=context.style
	var profile:Dictionary=context.get("country_appearance",{})
	if profile.is_empty():profile=ERA.capture(context.get("known",[]),context.get("fabric",{}))
	var slots:=_cluster_home_slots(at,count,seed_value)
	var groups:Dictionary={}
	var admitted:Array[Vector2]=[]
	var palette:Array[Dictionary]=[]
	# Three inherited types are enough to break repetition while keeping each
	# cluster's draw calls bounded. Palette and slot identity never depend on size.
	for index in (3 if count>=4 else 1):
		palette.append(ERA.home(profile,str(seed_value)+(":"+str(index) if index>0 else ""),style))
	for index in slots.size():
		var point:Vector2=slots[index]
		var descriptor:Dictionary=palette[index%palette.size()]
		var mesh:Mesh=ERA.mesh(descriptor)
		var rng:=RandomNumberGenerator.new();rng.seed=seed_value+index*7919
		var inward:Vector2=(at-point).normalized()
		var heading:=atan2(inward.x,inward.y)+rng.randf_range(-0.18,0.18)
		var basis:=SHAPES.lived_basis(heading,seed_value+index)
		if not _home_ground_valid(point,basis,mesh.get_aabb()):continue
		# Missing shore/fog slots stay empty. Never collapse their roofs onto the
		# cluster center, and never move the remaining roofs to close that gap.
		var transform:=Transform3D(basis,_point(point,0.0004))
		var key:=str(descriptor)
		if not groups.has(key):groups[key]={"descriptor":descriptor,"mesh":mesh,"transforms":[],"colors":[],"slots":[]}
		groups[key].transforms.append(transform)
		groups[key].colors.append(Color(style.get("tint",Color(0.94,0.89,0.78))).lerp(Color(0.8,0.76,0.67),rng.randf()*0.15))
		groups[key].slots.append(index);admitted.append(point)
	for key:String in groups:
		var group:Dictionary=groups[key]
		var transforms:Array[Transform3D]=[];transforms.assign(group.transforms)
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.mesh=group.mesh
		batch.instance_count=transforms.size()
		for index in transforms.size():
			batch.set_instance_transform(index,transforms[index]);batch.set_instance_color(index,group.colors[index])
		var node:=MultiMeshInstance3D.new();node.name="ScatteredHomes";node.multimesh=batch;node.material_override=INK.architecture_material()
		node.set_meta("source_transforms",transforms);node.set_meta("country_home",group.descriptor);node.set_meta("country_home_slots",group.slots)
		parent.add_child(node)
		INK.add_ground_shadows(parent,"FarmhouseShadow",transforms,(group.mesh as Mesh).get_aabb())
	parent.set_meta("country_home_count",admitted.size())
	parent.set_meta("country_home_positions",admitted)
	if admitted.is_empty():return
	# Shared objects sit around the yard, at most three for the whole cluster.
	var offsets:=[Vector2(0.007,0.002),Vector2(-0.006,0.004),Vector2(0.002,-0.007)]
	for index in mini(palette[0].props.size(),ERA.MAX_PROPS):
		_add_prop(parent,String(palette[0].props[index]),at+offsets[index],float(seed_value%31))

static func _cluster_home_slots(at:Vector2,count:int,seed_value:int)->Array[Vector2]:
	# Infill around an irregular yard and its short lanes, not a ring or a grid.
	# A fixed prefix preserves old roofs when a four-house knot grows to twelve.
	const OFFSETS:=[Vector2(-17,-12),Vector2(8,-18),Vector2(24,3),Vector2(-9,18),Vector2(-35,8),Vector2(13,33),Vector2(37,-22),Vector2(-20,-36),Vector2(-43,-19),Vector2(38,29),Vector2(-20,45),Vector2(4,-48)]
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var angle:=rng.randf()*TAU
	var slots:Array[Vector2]=[]
	for index in clampi(count,0,12):
		var offset:Vector2=OFFSETS[index]*0.001+Vector2(rng.randf_range(-0.002,0.002),rng.randf_range(-0.002,0.002))
		slots.append(at+offset.rotated(angle))
	return slots

func _home_ground_valid(point:Vector2,basis:Basis,bounds:AABB)->bool:
	if not _valid(point) or not bool(_visibility_cache.get(point,true)):return false
	for x:float in [bounds.position.x,bounds.end.x]:
		for z:float in [bounds.position.z,bounds.end.z]:
			var offset:=basis*Vector3(x,0,z)
			var corner:=point+Vector2(offset.x,offset.z)
			if not _valid(corner) or not bool(_visibility_cache.get(corner,true)):return false
	return true

func _add_prop(parent:Node3D,kind:String,point:Vector2,angle:float)->void:
	# These static household details share one close-view map budget.
	if kind in ["woodpile","pots","drying_rack","stored_grain","fishing_net"]:return
	if not _valid(point):return
	var prop:=MeshInstance3D.new();prop.name="Farm_"+kind
	prop.set_meta("country_prop",kind)
	prop.mesh=SHAPES.prop(kind);prop.material_override=INK.architecture_material()
	prop.transform=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*0.001),_point(point,0.0003))
	parent.add_child(prop)
