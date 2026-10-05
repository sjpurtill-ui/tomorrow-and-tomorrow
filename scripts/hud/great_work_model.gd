extends RefCounted
## One site's recorded construction, shared by inspection and dedication.
## Authored architecture follows the saved catalog identity and material.
## This close view separates building, scaffolding and unbuilt plan; it never
## advances a work.
const Map:=preload("res://scripts/undertaking_map_visual.gd")
const Catalog:=preload("res://scripts/undertaking_catalog.gd")
const Concept:=preload("res://scripts/wonder_concept.gd")
const U:=preload("res://scripts/undertaking_system.gd")
const Design:=preload("res://scripts/hud/great_work_design.gd")
const Architecture:=preload("res://scripts/hud/great_work_architecture.gd")
const COURSES:=40
const METRES:=1000.0
const MAX_WORKERS:=6
static var _stone:StandardMaterial3D
static var _plan:StandardMaterial3D
static var _earth:StandardMaterial3D
static var _joints:StandardMaterial3D

## A bounded, presentation-only snapshot. Site records have raw work units;
## works() summaries carry `work_id` and a fraction. site() supplies `fraction`.
static func describe(work:Dictionary)->Dictionary:
	if bool(work.get("_great_work_model",false)):return work.duplicate()
	var concept:Dictionary=work.get("concept",{}) if work.get("concept") is Dictionary else {}
	var id:=String(work.get("work_id",work.get("id",concept.get("id",""))))
	var definition:=Catalog.get_definition(id)
	var parsed:=Concept.parse(id)
	var design:=Design.describe(work)
	var shape:=String(design.form)
	var material:=String(design.material)
	if not Map.MATERIAL_TINTS.has(material):material="stone"
	var status:=String(work.get("status","plan"))
	var progress:=0.0
	if work.has("fraction"):progress=_number(work.fraction)
	elif work.has("work_id"):progress=_number(work.get("progress",0.0))
	elif work.has("progress") and not id.is_empty():
		progress=_number(work.progress)/maxf(.001,_number(work.get("total_work",float(definition.get("work",1.0))*_number(work.get("work_scale",1.0)))))
	progress=clampf(progress,0.0,1.0)
	var state:="building"
	if status in ["ruined","collapse","collapsed","folly"] or String(work.get("outcome",""))=="collapse":state="ruined"
	elif status in ["abandoned","rival","quarried"]:state="abandoned"
	elif status in ["functioning","standing","dedicated"] and progress>=.999999:state="standing"
	elif status=="plan":state="plan"
	var course:=mini(COURSES,floori(progress*COURSES+.0000001))
	var working:=status=="building" and _number(work.get("last_work",0.0))>0.0
	return {"_great_work_model":true,"id":id,"shape":shape,"map_shape":shape,"material":material,"design":design,"design_id":design.design_id,"valid":design.valid,
		"status":status,"state":state,"progress":progress,"course":course,"working":working,
		"condition":clampf(_number(work.get("condition",1.0)),0.0,1.0),"tier":int(parsed.get("tier",definition.get("tier",0))),
		"ambition":String(parsed.get("ambition",definition.get("ambition","grand"))),
		"name":String(work.get("display_name",work.get("custom_name",work.get("name",work.get("title",definition.get("title","Great work")))))),
		"idle":String(work.get("idle",work.get("reason",""))),"stage":String(work.get("stage",""))}

static func _number(value:Variant)->float:
	return float(value) if (value is float or value is int) and is_finite(float(value)) else 0.0

## Progress within a course changes its reading, not thousands of vertices.
static func signature(work:Dictionary)->String:
	var d:=describe(work)
	return str([d.id,d.design,d.state,d.course,d.working,roundi(float(d.condition)*10.0)])

## All dimensions and the returned AABB are metres. The root is unattached.
## Options: plan/scaffolds/workers/ground; callers own lights and the camera.
static func build(work:Dictionary,options:Dictionary={})->Dictionary:
	var d:=describe(work)
	var root:=Node3D.new();root.name="GreatWorkModel"
	var pieces:=_pieces(d)
	var footprint:=Architecture.footprint(pieces)
	var plinth:=footprint.grow(Map.PLINTH_MARGIN)
	var design_height:=maxf(0.0,Architecture.extent(pieces).end.y)
	var fraction:=float(d.course)/COURSES
	var level:=design_height*fraction
	var top:=Map.PLINTH_RISE
	var body:=SurfaceTool.new();body.begin(Mesh.PRIMITIVE_TRIANGLES)
	var joints:=SurfaceTool.new();joints.begin(Mesh.PRIMITIVE_LINES)
	var joint_count:=0
	var tone:Color=Map.MATERIAL_TINTS[d.material]
	# A cleared site is visible at zero; no first 8% is invented.
	Map.append_piece(body,Map.piece(Vector3(plinth.get_center().x,-.0015,plinth.get_center().y),Vector3(plinth.size.x,.0015,plinth.size.y),Color("98866b")),0.0)
	if fraction>0.0:
		Map.append_piece(body,Map.piece(Vector3(plinth.get_center().x,0,plinth.get_center().y),Vector3(plinth.size.x,top,plinth.size.y),tone.lerp(Color("c5c0b2"),.40)),0.0)
	if d.state=="ruined":level=design_height*minf(.42,fraction*.65)
	for index in pieces.size():
		var part:Dictionary=pieces[index].duplicate()
		var base:=float(part.position.y)
		var unfinished:bool=d.state!="standing"
		if unfinished:
			if part.kind=="water" or bool(part.get("finish",false)) or Architecture.extent([part]).position.y>=level-.000001:continue
			if d.state in ["abandoned","ruined"]:part.color=(part.color as Color).lerp(Map.WEATHERED,.5)
		part.position.y=base+top
		Architecture.append_piece(body,part,level+top if unfinished else INF)
		if d.material in ["stone","brick","concrete"] and part.kind=="box":joint_count+=_course_lines(joints,part,String(d.material),level+top if unfinished else INF)
	_add_mesh(root,"Masonry",body.commit(),_material())
	if joint_count>0:_add_mesh(root,"Courses",joints.commit(),_joint_material())
	if bool(options.get("scaffolds",true)) and d.state=="building" and fraction>0.0:
		var frame:=SurfaceTool.new();frame.begin(Mesh.PRIMITIVE_TRIANGLES)
		Map._scaffold(frame,footprint,level,design_height,top,0.0)
		_add_mesh(root,"Scaffolding",frame.commit(),_material())
	if bool(options.get("plan",false)) and d.state in ["building","abandoned","plan"]:
		var plan:=_plan_mesh(pieces,level,top)
		if plan!=null:_add_mesh(root,"UnbuiltPlan",plan,_plan_material())
	var worker_count:=0
	if bool(options.get("workers",false)) and bool(d.working):
		worker_count=MAX_WORKERS
		_add_mesh(root,"Builders",_workers(footprint,top,int(d.tier)),_material())
	if bool(options.get("ground",false)):_ground(root,plinth)
	# Fit the finished design, so foundations and later courses share a camera.
	var bounds:=AABB(Vector3(plinth.position.x,-.0015,plinth.position.y)*METRES,Vector3(plinth.size.x,design_height+top+.0015,plinth.size.y)*METRES)
	root.set_meta("work_id",d.id);root.set_meta("design_id",d.design_id);root.set_meta("course",d.course);root.set_meta("progress",d.progress)
	return {"root":root,"bounds":bounds,"progress":d.progress,"course":d.course,"worker_count":worker_count,"signature":signature(d),"description":d,"design_id":d.design_id}

static func _pieces(d:Dictionary)->Array:
	var pieces:=Architecture.pieces(d.design)
	for part:Dictionary in pieces:
		if part.kind!="water":part.color=(part.color as Color).lerp(Map.WEATHERED,(1.0-roundf(float(d.condition)*10.0)/10.0)*.3)
	return pieces

static func _add_mesh(root:Node3D,label:String,mesh:Mesh,material:Material)->MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=label;node.mesh=mesh;node.material_override=material
	node.scale=Vector3.ONE*METRES;root.add_child(node)
	return node

static func _material()->StandardMaterial3D:
	if _stone==null:
		# Map palettes are authored sRGB, like albedo textures, not linear light.
		_stone=StandardMaterial3D.new();_stone.vertex_color_use_as_albedo=true;_stone.vertex_color_is_srgb=true;_stone.roughness=.92
	return _stone

static func _plan_material()->StandardMaterial3D:
	if _plan==null:
		_plan=StandardMaterial3D.new();_plan.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		_plan.albedo_color=Color("746348");_plan.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;_plan.albedo_color.a=.65
		_plan.no_depth_test=false
	return _plan

static func _plan_mesh(pieces:Array,level:float,top:float)->ArrayMesh:
	var lines:=SurfaceTool.new();lines.begin(Mesh.PRIMITIVE_LINES)
	var count:=0
	# Box edge guides describe only the volume that has yet to be raised.
	for part:Dictionary in pieces:
		if part.kind=="water" or not bool(part.get("plan",true)) or Architecture.extent([part]).end.y<=level:continue
		var base:=maxf(float(part.position.y),level)+top
		var height:=float(part.position.y)+float(part.size.y)+top-base
		var corners:Array[Vector3]=[]
		var basis:Basis=part.get("basis",Basis.IDENTITY)
		for y in [0.0,float(part.size.y)]:
			for z in [-.5,.5]:
				for x in [-.5,.5]:corners.append(basis*Vector3(part.size.x*x,y,part.size.z*z)+part.position+Vector3.UP*top)
		for edge:Array in [[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]:
			var a:Vector3=corners[edge[0]];var b:Vector3=corners[edge[1]]
			if maxf(a.y,b.y)<level+top:continue
			if a.y<level+top:a=a.lerp(b,(level+top-a.y)/(b.y-a.y))
			elif b.y<level+top:b=b.lerp(a,(level+top-b.y)/(a.y-b.y))
			lines.add_vertex(a);lines.add_vertex(b)
			count+=1
	return lines.commit() if count>0 else null

static func _joint_material()->StandardMaterial3D:
	if _joints==null:
		_joints=StandardMaterial3D.new();_joints.albedo_color=Color("756957");_joints.roughness=1.0
	return _joints

static func _course_lines(lines:SurfaceTool,part:Dictionary,material:String,limit:float=INF)->int:
	if part.size.x<.008 or part.size.z<.008:return 0
	var spacing:=.00065 if material=="brick" else (.004 if material=="concrete" else .0014)
	var count:=0
	for row in mini(48,floori(float(part.size.y)/spacing)):
		var y:=float(part.position.y)+float(row+1)*spacing
		if y>=float(part.position.y)+float(part.size.y)-.00005:break
		var x:=float(part.size.x)*.5+.000015;var z:=float(part.size.z)*.5+.000015
		if y>limit:break
		var p:Vector3=part.position;var basis:Basis=part.get("basis",Basis.IDENTITY)
		var corners:Array[Vector3]=[]
		for local:Vector3 in [Vector3(-x,y-p.y,-z),Vector3(x,y-p.y,-z),Vector3(x,y-p.y,z),Vector3(-x,y-p.y,z)]:corners.append(basis*local+p)
		for side in 4:lines.add_vertex(corners[side]);lines.add_vertex(corners[(side+1)%4])
		count+=1
	return count

static func _workers(footprint:Rect2,top:float,tier:int)->ArrayMesh:
	var people:=SurfaceTool.new();people.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in MAX_WORKERS:
		var at:=Vector3(footprint.position.x+footprint.size.x*(.12+.15*i),top,footprint.end.y+.003)
		var cloth:=Color("c0aa82") if tier<4 else Color("64787d")
		Map.append_piece(people,Map.piece(at,Vector3(.00055,.0012,.00035),cloth.darkened(.06*(i%3))),0.0)
		Map.append_piece(people,Map.piece(at+Vector3(0,.00115,0),Vector3(.00037,.00042,.00037),Color("936b4b"),"dome"),0.0)
		Map.append_piece(people,Map.piece(at+Vector3(.0004,.0005,0),Vector3(.0009,.00012,.00012),Map.WOOD),0.0)
	return people.commit()

static func _ground(root:Node3D,plinth:Rect2)->void:
	var disk:=CylinderMesh.new();disk.top_radius=plinth.size.length()*METRES*.64;disk.bottom_radius=disk.top_radius
	disk.height=1.0;disk.radial_segments=64;disk.rings=1
	if _earth==null:
		_earth=StandardMaterial3D.new();_earth.roughness=1.0;_earth.uv1_scale=Vector3(10,10,1)
		var image:=Image.create_empty(64,64,false,Image.FORMAT_RGB8)
		var noise:=FastNoiseLite.new();noise.seed=1846;noise.frequency=.12;noise.fractal_octaves=3
		for y in 64:
			for x in 64:
				var grain:=float(posmod(x*73+y*131+x*y*17,97))/96.0
				# Blend opposite samples for a seamless, irregular soil texture.
				var a:=lerpf(noise.get_noise_2d(x,y),noise.get_noise_2d(x-64,y),float(x)/64.0)
				var b:=lerpf(noise.get_noise_2d(x,y-64),noise.get_noise_2d(x-64,y-64),float(x)/64.0)
				var earth:=clampf(.5+lerpf(a,b,float(y)/64.0)+(grain-.5)*.18,0.0,1.0)
				image.set_pixel(x,y,Color("9b9180").lerp(Color("b5aa96"),earth))
		_earth.albedo_texture=ImageTexture.create_from_image(image)
	var ground:=MeshInstance3D.new();ground.name="Ground";ground.mesh=disk;ground.material_override=_earth;ground.position.y=-.8
	root.add_child(ground)
