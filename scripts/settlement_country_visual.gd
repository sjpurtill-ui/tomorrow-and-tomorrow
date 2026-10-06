extends Node3D
## Bounded landscape representatives, never homes, sites or routes in the ledger.
## Geometry is in world kilometres. Retained patches share the town's build queue
## implementation and are replaced only when their own visible facts change.
const PLAN = preload("res://scripts/settlement_country_plan.gd")
const PATCHES = preload("res://scripts/settlement_patch_renderer.gd")
const EARLY = preload("res://scripts/early_settlement_visual.gd")
const TOWN = preload("res://scripts/organic_town_visual.gd")
const INK = preload("res://scripts/settlement_ink.gd")
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
var _fog_clipped:=false

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
	var key:=hash([plan_key,style])
	if key==last_signature:return
	last_signature=key;requests+=1
	if plan_key!=last_plan_signature:
		plan=PLAN.build(snapshot);last_plan_signature=plan_key
	var entries:Array[Dictionary]=[]
	var anchors:Array[Vector2]=[Vector2(snapshot.get("origin",Vector2.ZERO))]
	var known:Array=[]
	for id:String in ["thatched_roofing","joinery","dry_stone_walls","dressed_stone_masonry","kiln_fired_bricks","adobe_wall_construction","mould_made_mudbricks","framed_construction","timber_post_beam_connections"]:
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
			var appearance:=[point,record.get("category",""),record.get("age",""),record.get("resource",""),record.get("field_radius_km",0.0),record.get("radius_km",0.0),record.get("buildings",2),nearest,admitted,start_seen,clipped_revision]
			entries.append({"key":id,"signature":hash([appearance,context,surface_revision]),"priority":point.distance_squared_to(anchors[0]),"build":_build_patch.bind(record,context)})
	retained.request(entries)
	request_usec=Time.get_ticks_usec()-began

func process_jobs(budget_usec:int=2000,max_jobs:int=2)->void:
	if retained!=null:retained.process(budget_usec,max_jobs)

func stats()->Dictionary:
	var result:Dictionary=retained.stats() if retained!=null else {}
	result["requests"]=requests;result["request_usec"]=request_usec
	result["homesteads"]=plan.get("homesteads",[]).size()
	result["herders"]=plan.get("herders",[]).size()
	result["sites"]=plan.get("sites",[]).size()
	return result

func _valid(point:Vector2)->bool:
	if visibility_at.is_valid() and not bool(visibility_at.call(point)):_fog_clipped=true
	if not _land_cache.has(point):_land_cache[point]=not land_at.is_valid() or bool(land_at.call(point))
	return bool(_land_cache[point])

func _point(point:Vector2,lift:float=0.0015)->Vector3:
	if not _height_cache.has(point):_height_cache[point]=float(height_at.call(point))
	return Vector3(point.x,float(_height_cache[point])+lift,point.y)

func _tri(surface:SurfaceTool,a:Vector2,b:Vector2,c:Vector2,color:Color,lift:float=0.0015)->void:
	_graded_tri(surface,a,b,c,color,color,color,lift)

func _graded_tri(surface:SurfaceTool,a:Vector2,b:Vector2,c:Vector2,ca:Color,cb:Color,cc:Color,lift:float=0.0025,depth:int=0)->void:
	# Smaller ground facets follow relief rather than making a flat polygon lid.
	if depth<2 and maxf(a.distance_squared_to(b),maxf(b.distance_squared_to(c),c.distance_squared_to(a)))>0.16:
		var ab:=(a+b)*0.5;var bc:=(b+c)*0.5;var ac:=(a+c)*0.5
		var cab:=ca.lerp(cb,0.5);var cbc:=cb.lerp(cc,0.5);var cac:=ca.lerp(cc,0.5)
		_graded_tri(surface,a,ab,ac,ca,cab,cac,lift,depth+1)
		_graded_tri(surface,ab,b,bc,cab,cb,cbc,lift,depth+1)
		_graded_tri(surface,ac,bc,c,cac,cbc,cc,lift,depth+1)
		_graded_tri(surface,ab,bc,ac,cab,cbc,cac,lift,depth+1)
		return
	if not _valid(a) or not _valid(b) or not _valid(c) or not _valid((a+b+c)/3.0):return
	var points:=[a,b,c];var colors:=[ca,cb,cc]
	for i in 3:
		surface.set_color(colors[i]);surface.set_normal(Vector3.UP);surface.add_vertex(_point(points[i],lift))

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

func _field(surface:SurfaceTool,center:Vector2,radius:float,color:Color,angle:float)->void:
	var along:=Vector2.from_angle(angle)*radius
	var across:=along.orthogonal()*0.38
	var corners:=[center-along-across,center+along*0.83-across*0.92,center+along+across*0.85,center-along*0.92+across]
	var edge:=color;edge.a=0.0
	for i in 4:_graded_tri(surface,center,corners[i],corners[(i+1)%4],color,edge,edge)

func _track(surface:SurfaceTool,start:Vector2,finish:Vector2,seed_value:int,tier:int)->void:
	var length:=start.distance_to(finish)
	if length<0.01:return
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var cross:=(finish-start).normalized().orthogonal()
	var pieces:=clampi(ceili(length/0.65),4,64)
	var previous:=start
	var bend:=rng.randf_range(-0.07,0.07)*minf(length,10.0)
	for i in range(1,pieces+1):
		var t:=float(i)/float(pieces)
		var point:=start.lerp(finish,t)+cross*sin(t*PI)*(bend+sin(t*PI*3.0+float(seed_value%17))*minf(length,3.0)*0.025)
		var width:=lerpf(0.006 if tier==2 else 0.003,0.0012,t)
		var side:=(point-previous).normalized().orthogonal()*width*0.5
		var color:=Color("#978465") if tier<2 else Color("#a3987c")
		color.a=0.45
		_tri(surface,previous-side,previous+side,point+side,color,0.002)
		_tri(surface,previous-side,point+side,point-side,color,0.002)
		previous=point

func _build_patch(parent:Node3D,record:Dictionary,context:Dictionary)->void:
	_land_cache.clear();_height_cache.clear()
	_fog_clipped=false
	var at:Vector2=record.position
	if not _valid(at):
		parent.set_meta("fog_clipped",_fog_clipped)
		return
	var seed_value:=absi(hash(record.get("id",at)))
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var group:=String(record.group)
	if group=="sites":
		_draw_site(surface,record,seed_value)
	else:
		var sparse:=group=="herders"
		var radius:=float(record.get("field_radius_km",0.19))*(0.35 if sparse else 1.0)
		var fields:=1 if sparse else 4
		for i in fields:
			var center:=at+Vector2.from_angle(rng.randf()*TAU)*radius*rng.randf_range(0.12,0.8)
			var color:=Color("#a89468").lerp(Color("#7e8150"),rng.randf())
			color.a=0.28 if sparse else 0.82
			_field(surface,center,radius*rng.randf_range(0.65,1.0),color,float(record.get("rotation",0.0))+rng.randf_range(-0.22,0.22))
		_add_homes(parent,at,1 if sparse else int(record.get("buildings",2)),seed_value,context)
	# Exposed rock exhausted long ago has no new busy track; living woods and
	# staffed workplaces retain access. Thin ground-coloured paths disappear
	# naturally at realm zoom, rather than becoming chart-wide spokes.
	if group!="sites" or String(record.get("category",""))!="depleted":
		_track(surface,Vector2(record.track_from),at,seed_value,int(record.get("road_tier",context.road_tier)))
	parent.set_meta("fog_clipped",_fog_clipped)
	var arrays:=surface.commit_to_arrays()
	if arrays.is_empty() or (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():return
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
	var color:=Color("#a89468")
	if "wood" in age or resource=="Timber":color=Color("#929669") if category=="regrowing" else Color("#9e946f")
	elif "quarry" in age or resource=="Stone":color=Color("#aaa18d") if category=="depleted" else Color("#b6a58b")
	elif resource in ["Plant Fiber","Fiber Plants"]:color=Color("#989464")
	color.a=0.78 if category=="depleted" else 0.52
	_wash(surface,at,radius,color,seed_value,1.2)
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+41
	for i in 5:
		var patch:=at+Vector2.from_angle(rng.randf()*TAU)*radius*rng.randf_range(0.15,0.85)
		var tint:=color.darkened(rng.randf_range(0.12,0.32));tint.a=0.30
		if category=="regrowing":tint=Color(0.48,0.55,0.32,0.38)
		_wash(surface,patch,radius*rng.randf_range(0.05,0.18),tint,seed_value+71+i)

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
		var offset:=Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(0.0,0.026)
		var point:=at+offset
		if not _valid(point):point=at
		# The shared kit is authored in metres; the map is in kilometres.
		var basis:=preload("res://scripts/settlement_kit_shapes.gd").lived_basis(rng.randf()*TAU,seed_value+i)
		var transform:=Transform3D(basis,_point(point,0.0003))
		transforms.append(transform);batch.set_instance_transform(i,transform)
		batch.set_instance_color(i,Color(style.get("tint",Color(0.94,0.89,0.78))).lerp(Color(0.8,0.76,0.67),rng.randf()*0.15))
	var node:=MultiMeshInstance3D.new();node.name="ScatteredHomes";node.multimesh=batch;node.material_override=INK.material()
	node.set_meta("source_transforms",transforms)
	parent.add_child(node)
