extends Node3D
## Bounded landscape representatives, never homes, sites or routes in the ledger.
## Geometry is in world kilometres. Retained patches share the town's build queue
## implementation and are replaced only when their own visible facts change.
const PLAN = preload("res://scripts/settlement_country_plan.gd")
const PATCHES = preload("res://scripts/settlement_patch_renderer.gd")
const EARLY = preload("res://scripts/early_settlement_visual.gd")
const TOWN = preload("res://scripts/organic_town_visual.gd")
const INK = preload("res://scripts/settlement_ink.gd")
const SHAPES = preload("res://scripts/settlement_kit_shapes.gd")
const CHART = preload("res://scripts/settlement_country_chart.gd")
const DRAPE = preload("res://scripts/settlement_country_drape.gd")
const GROUND_LIFT_KM:=0.0002
var ground_grid:=Vector4.ZERO
var view_center:=Vector2.ZERO
var drape_budget_skips:=0
var height_at:Callable
var land_at:Callable
var visibility_at:Callable
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
const MAX_PREPARE_STEPS:=512

func invalidate(drape:bool=true)->void:
	# Rendered terrain and discovery masks can change without a simulation day.
	if drape:surface_revision+=1
	else:fog_revision+=1
	last_signature=-1

func configure(height:Callable,land:Callable=Callable(),revealed:Callable=Callable())->void:
	height_at=height;land_at=land;visibility_at=revealed
	if retained==null:retained=PATCHES.new(self)
	if material==null:
		material=ShaderMaterial.new()
		material.shader=preload("res://scripts/shaders/settlement_country_ground.gdshader")

func request(snapshot:Dictionary,style:Dictionary={})->void:
	var began:=Time.get_ticks_usec()
	var plan_key:=PLAN.signature(snapshot)
	var key:=hash([plan_key,style,view_center])
	if key==last_signature:return
	last_signature=key;requests+=1
	if plan_key!=last_plan_signature:
		plan=PLAN.build(snapshot);last_plan_signature=plan_key
	var entries:Array[Dictionary]=[]
	var anchors:Array[Vector2]=[Vector2(snapshot.get("origin",Vector2.ZERO))]
	var known:Array=[]
	for id:String in ["thatched_roofing","joinery","dry_stone_walls","dressed_stone_masonry","kiln_fired_bricks","adobe_wall_construction","mould_made_mudbricks","framed_construction","timber_post_beam_connections","grain_grinding","saddle_quern"]:
		if id in snapshot.get("knowledge",[]):known.append(id)
	var homes:Array=[]
	for share in snapshot.get("built_fabric",{}).get("homes",[]):homes.append(roundf(float(share)*10.0)/10.0)
	var context:Dictionary={"origin":snapshot.get("origin",Vector2.ZERO),"road_tier":snapshot.get("road_tier",0),"known":known,"fabric":{"homes":homes},"style":style.duplicate(true)}
	for kind:String in ["homesteads","herders","sites"]:
		for source:Dictionary in plan.get(kind,[]):
			var record:=source.duplicate(true)
			record["group"]=kind
			var point:Vector2=record.position
			var nearest:Vector2=anchors[0]
			var distance:=point.distance_squared_to(nearest)
			for anchor:Vector2 in anchors:
				var test:=point.distance_squared_to(anchor)
				if test<distance:nearest=anchor;distance=test
			if kind=="herders":nearest=point.move_toward(anchors[0],minf(2.0,point.distance_to(anchors[0])))
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
			var appearance:=[point,record.get("category",""),record.get("age",""),record.get("resource",""),record.get("field_radius_km",0.0),record.get("radius_km",0.0),record.get("buildings",2),nearest,admitted,start_seen,clipped_revision]
			entries.append({"key":id,"signature":hash([appearance,context,surface_revision]),"priority":point.distance_squared_to(view_center),"build":_build_patch.bind(record,context)})
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
	_commands=[];_collected_surface=null;_collecting=true
	(source.build as Callable).call(staging)
	_collecting=false
	_commands.reverse()
	_job={"key":key,"signature":source.signature,"node":staging,"surface":_collected_surface,"commands":_commands,"pieces":[],"piece_index":0,"lift":GROUND_LIFT_KM,"center_check":false,"work_usec":Time.get_ticks_usec()-began}
	_commands=[];_collected_surface=null

func _advance_job()->bool:
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
	return result

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

func _ribbon(surface:SurfaceTool,start:Vector2,finish:Vector2,width:float,color:Color)->void:
	var side:=(finish-start).normalized().orthogonal()*width*0.5
	_tri(surface,start-side,start+side,finish+side,color)
	_tri(surface,start-side,finish+side,finish-side,color)

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
	_land_cache.clear();_height_cache.clear();_visibility_cache.clear()
	_fog_clipped=false
	var at:Vector2=record.position
	if not _valid(at):
		parent.set_meta("fog_clipped",_fog_clipped)
		return
	var seed_value:=absi(hash(record.get("id",at)))
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var group:=String(record.group)
	var chart:=CHART.create(record,height_at)
	if chart!=null:parent.add_child(chart)
	if group=="sites":
		_draw_site(surface,record,seed_value)
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
	# Exposed rock exhausted long ago has no new busy track; living woods and
	# staffed workplaces retain access. Thin ground-coloured paths disappear
	# naturally at realm zoom, rather than becoming chart-wide spokes.
	if group!="sites" or String(record.get("category",""))!="depleted":
		var finish:=at
		if group!="sites":finish=at.move_toward(Vector2(record.track_from),float(PLAN.homestead_layout(record).yard_radius_km)*0.78)
		_track(surface,Vector2(record.track_from),finish,seed_value,int(record.get("road_tier",context.road_tier)))
	parent.set_meta("fog_clipped",_fog_clipped)
	if _collecting:
		_collected_surface=surface
		return
	_finish_surface(parent,surface)

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
		var size:=radius*rng.randf_range(0.20,0.37)
		var tint:=color.darkened(rng.randf_range(0.02,0.16));tint.a=0.68
		if category=="regrowing":tint=Color(0.53,0.59,0.35,0.66)
		_wash(surface,patch,size,tint,seed_value+71+i,1.15)
		if "quarry" in age or resource=="Stone":
			var direction:=Vector2.from_angle(float(record.get("rotation",0.0))+0.4)
			for row in 3:
				var line:=patch+direction.orthogonal()*size*(float(row)-1.0)*0.38
				_ribbon(surface,line-direction*size*0.65,line+direction*size*0.5,size*0.075,Color(0.40,0.37,0.32,0.62))

func _add_homes(parent:Node3D,at:Vector2,count:int,seed_value:int,context:Dictionary)->void:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var known:Array=context.known
	var style:Dictionary=context.style
	var kinds:Array=style.get("kinds",["rooted_lean_to"])
	var homes:Array=(context.fabric as Dictionary).get("homes",[])
	var roll:=rng.randf();var grade:=0
	for i in homes.size():
		roll-=float(homes[i])
		if roll<=0.0:grade=i;break
	var kind:String=kinds[seed_value%kinds.size()]
	if style.is_empty():
		kind="round_household" if "thatched_roofing" in known or "joinery" in known else "rooted_lean_to"
	if grade>=4 and ("dry_stone_walls" in known or "dressed_stone_masonry" in known or "kiln_fired_bricks" in known):kind="rubble_household"
	elif grade>=3 and ("adobe_wall_construction" in known or "mould_made_mudbricks" in known):kind="earthen_household"
	elif grade>=2 and ("framed_construction" in known or "timber_post_beam_connections" in known):kind="house_small"
	var mesh:Mesh=TOWN.kit_mesh(TOWN.KIT.find(kind)) if kind in TOWN.KIT else EARLY.kit_mesh(kind)
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.mesh=mesh
	batch.instance_count=clampi(count,1,3)
	var transforms:Array[Transform3D]=[]
	for i in batch.instance_count:
		var offset:=Vector2.from_angle(float(seed_value%628)*0.01+float(i)*PI)*rng.randf_range(0.006,0.014)
		var point:=at+offset
		if not _valid(point):point=at
		# The shared kit is authored in metres; the map is in kilometres.
		var basis:=preload("res://scripts/settlement_kit_shapes.gd").lived_basis(rng.randf()*TAU,seed_value+i)
		var transform:=Transform3D(basis,_point(point,0.0004))
		transforms.append(transform);batch.set_instance_transform(i,transform)
		batch.set_instance_color(i,Color(style.get("tint",Color(0.94,0.89,0.78))).lerp(Color(0.8,0.76,0.67),rng.randf()*0.15))
	var node:=MultiMeshInstance3D.new();node.name="ScatteredHomes";node.multimesh=batch;node.material_override=INK.architecture_material()
	node.set_meta("source_transforms",transforms)
	parent.add_child(node)
	INK.add_ground_shadows(parent,"FarmhouseShadow",transforms,mesh.get_aabb())
	# Quiet household objects establish a compound at close zoom; never figures.
	for i in transforms.size():
		var origin:Vector3=transforms[i].origin
		var home:=Vector2(origin.x,origin.z)
		_add_prop(parent,"woodpile",home+Vector2(0.005,0.001),float(seed_value%31))
		if "grain_grinding" in known or "saddle_quern" in known:
			_add_prop(parent,"quern",home+Vector2(-0.004,0.003),0.0)

func _add_prop(parent:Node3D,kind:String,point:Vector2,angle:float)->void:
	if not _valid(point):return
	var prop:=MeshInstance3D.new();prop.name="Farm_"+kind
	prop.mesh=SHAPES.prop(kind);prop.material_override=INK.architecture_material()
	prop.transform=Transform3D(Basis(Vector3.UP,angle).scaled(Vector3.ONE*0.001),_point(point,0.0003))
	parent.add_child(prop)
