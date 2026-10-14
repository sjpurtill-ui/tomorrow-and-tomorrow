extends Control
## Living, private view of recorded settlement fabric. The economy remains in
## its existing authorities; this scene only presents copied plots and routes.
signal role_anchors_changed(anchors:Dictionary)
signal focus_changed(role:String)
signal role_selected(role:String)

const Snapshot=preload("res://scripts/hud/people_settlement_scene.gd")
const Early=preload("res://scripts/early_settlement_visual.gd")
const Ground=preload("res://scripts/early_settlement_ground.gd")
const Yards=preload("res://scripts/settlement_yard_details.gd")
const Setting=preload("res://scripts/hud/people_settlement_environment.gd")
const Life=preload("res://scripts/map_life_ink.gd")
const Shapes=preload("res://scripts/settlement_kit_shapes.gd")
const MAX_PEOPLE:=48
const GRID:=41
var view:SubViewport
var camera:Camera3D
var picture:TextureRect
var model:Node3D
var focused_role:=""
var snapshot:Dictionary={}
var geometry_builds:=0
var visual_people_count:=0
var _context:Dictionary={}
var _key:int=0
var _terrain:Node
var _zones:Dictionary={}
var _anchors:Dictionary={}
var _materials:Array[ShaderMaterial]=[]
var _bounds:=Rect2()
var _ground_bounds:=Rect2()
var _heights:=PackedFloat32Array()
var _target:=Vector3.ZERO
var _desired_target:=Vector3.ZERO
var _span:=.1
var _desired_span:=.1
var _yaw:=-.60
var _pitch:=.51
var _elapsed:=0.0
var _people:MultiMeshInstance3D
var _walks:Array[Dictionary]=[]
var _highlight:MeshInstance3D
var _dragged:=false
var _yards:Node3D
var _yard_batches:=-1
var _people_paint:ShaderMaterial
var _building_plan:Dictionary={}
var _people_key:=-1

func configure(context:Dictionary)->void:
	_ensure_view();update_state(context)

func _ready()->void:
	_ensure_view()
	resized.connect(_resize_view)
	visibility_changed.connect(_visibility_changed)
	_resize_view()

func _ensure_view()->void:
	if is_instance_valid(view):return
	name="PeopleSettlementView";mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(240,360);size_flags_horizontal=Control.SIZE_EXPAND_FILL
	picture=TextureRect.new();picture.name="LivingSettlement"
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_SCALE
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(picture)
	view=SubViewport.new();view.name="PeopleSettlementWorld";view.own_world_3d=true
	view.size=Vector2i(1024,640);view.gui_disable_input=true;view.msaa_3d=Viewport.MSAA_4X
	view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;add_child(view)
	picture.texture=view.get_texture()
	camera=Camera3D.new();camera.name="SettlementCamera";camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=38.0
	camera.near=.0001;camera.far=10.0;camera.current=true;view.add_child(camera)
	var world:=WorldEnvironment.new();var environment:=Environment.new();world.environment=environment
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("87968c")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("c5d5df");environment.ambient_light_energy=.24
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;view.add_child(world)
	var sun:=DirectionalLight3D.new();sun.name="WarmAfternoon"
	sun.rotation_degrees=Vector3(-42,-34,0);sun.light_color=Color("fff0d5");sun.light_energy=.40
	# Painted terrain and ink meshes share draped contact shading below. A
	# hardware shadow received only by the roads would end sharply at their edge.
	sun.shadow_enabled=false;sun.directional_shadow_max_distance=4.0
	sun.shadow_bias=.001;sun.shadow_normal_bias=.003;view.add_child(sun)
	gui_input.connect(_input_view)

func update_state(context:Dictionary)->void:
	_ensure_view();_context=context.duplicate(false);_terrain=context.get("terrain")
	var next:=Snapshot.snapshot(context);var key:=hash([Snapshot.signature(next),Ground.known_crafts(),_terrain.get_instance_id() if is_instance_valid(_terrain) else 0])
	if key!=_key or not is_instance_valid(model):
		snapshot=next;_key=key;_build_scene()
	else:
		_update_people()
	_resize_view()

func focus_role(role:String)->void:
	if not _zones.has(role):return
	focused_role=role
	var zone:Dictionary=_zones[role];var at:Vector2=zone.center
	_desired_target=_point(at)
	var area:Rect2=zone.bounds
	_desired_span=clampf(maxf(area.size.x,area.size.y)*.82,.018,_overview_span())
	_make_highlight(zone.polygons)
	focus_changed.emit(role)

func reset_view()->void:
	focused_role="";_desired_target=_point(_bounds.get_center());_desired_span=_overview_span()
	if is_instance_valid(_highlight):_highlight.visible=false
	focus_changed.emit("")

func role_screen_positions()->Dictionary:return _anchors.duplicate()

func role_anchor_metadata()->Dictionary:
	var result:Dictionary={}
	for role:String in _zones:
		var zone:Dictionary=_zones[role];var at:Vector2=zone.center
		var point:=_point(at,.003)
		result[role]={"position":_anchors.get(role,Vector2.ZERO),"visible":not camera.is_position_behind(point) and Rect2(Vector2.ZERO,size).has_point(_anchors.get(role,Vector2.ZERO)),"physical":zone.physical,"plot_ids":zone.plot_ids.duplicate(),"source":zone.source}
	return result

func _build_scene()->void:
	if is_instance_valid(model):model.free()
	_materials.clear();_walks.clear();_people=null;_highlight=null;_yards=null;_yard_batches=-1;_people_key=-1
	model=Node3D.new();model.name="RecordedSettlement";view.add_child(model)
	_bounds=Snapshot.bounds(snapshot.plots,snapshot.routes)
	_ground_bounds=_bounds.grow(maxf(_bounds.size.x,_bounds.size.y)*2.2+.08)
	_sample_ground();_landscape()
	Setting.render(_terrain,snapshot,_ground_bounds,_point,model)
	var land:=func(at:Vector2)->bool:
		if is_instance_valid(_terrain) and _terrain.has_method("_settlement_stage_land_at"):
			return bool(_terrain.call("_settlement_stage_land_at",at+Vector2(snapshot.origin.x,snapshot.origin.z)))
		return true
	var height:=func(x:float,z:float)->float:return _height(Vector2(x,z))
	var plan:Dictionary=Early.layout(snapshot.plots,snapshot.routes,land)
	_building_plan=plan
	_frame_inhabited_core(plan)
	_worked_yards(plan)
	Early.render(plan,Vector3.ZERO,height,model)
	Ground.render(plan,snapshot.plots,snapshot.routes,Vector3.ZERO,height,land,model,false)
	_workplace_props(plan)
	_yards=Yards.new();_yards.name="OccupiedHouseholdYards";model.add_child(_yards)
	_yards.configure(func(at:Vector2)->float:return _height(at),land)
	var knowledge:Array=GameState.known_discoveries.duplicate()
	for entry in GameState.discovery_log:
		if entry is Dictionary:knowledge.append(String(entry.get("id","")))
	var sources:Array[Dictionary]=[{"id":"people-view","origin":Vector2.ZERO,"plan":plan,"plots":snapshot.plots,"routes":snapshot.routes,"knowledge":knowledge}]
	_yards.request(sources,_key)
	_private_paint(model)
	_zones=Snapshot.zones(snapshot.plots,snapshot.routes)
	geometry_builds+=1;_update_people()
	if _zones.has(focused_role):focus_role(focused_role)
	else:reset_view()
	_target=_desired_target;_span=_desired_span;_position_camera();_project_anchors()

func _frame_inhabited_core(plan:Dictionary)->void:
	var points:=PackedVector2Array()
	for record:Dictionary in plan.get("buildings",[]):
		var plot:Dictionary=record.plot
		if String(plot.get("status","active")) in ["ruin","reclaimed","vacant"]:continue
		var use:=String(plot.get("land_use",""))
		if use not in ["residential_compound","mixed_household","temporary_encampment","workshop","storage","civic"]:continue
		var at:Vector2=record.position;var radius:=float(record.get("radius",.003))
		points.append(at-Vector2.ONE*radius);points.append(at+Vector2.ONE*radius)
	if points.is_empty():return
	_bounds=Rect2(points[0],Vector2.ZERO)
	for point in points:_bounds=_bounds.expand(point)
	_bounds=_bounds.grow(.002)

func _private_paint(node:Node)->void:
	for child in node.get_children():
		if child is GeometryInstance3D and child.material_override is ShaderMaterial:
			var source:ShaderMaterial=child.material_override;var paint:ShaderMaterial=source.duplicate()
			paint.set_shader_parameter("map_cloud",Vector4.ZERO);paint.set_shader_parameter("map_wind",Vector4.ZERO)
			paint.set_shader_parameter("hearth",Vector4.ZERO);paint.set_shader_parameter("anim_clock",0.0)
			paint.set_shader_parameter("vertex_srgb",true)
			if source.next_pass is ShaderMaterial:
				var outline:ShaderMaterial=source.next_pass.duplicate();outline.set_shader_parameter("outline_px",.7)
				paint.next_pass=outline;_materials.append(outline)
			child.material_override=paint
		_private_paint(child)

func _sample_ground()->void:
	_heights.resize(GRID*GRID)
	var sampled:=is_instance_valid(_terrain) and _terrain.has_method("_height_at")
	var origin:Vector3=snapshot.origin;var base:=float(_terrain.call("_height_at",origin.x,origin.z)) if sampled else 0.0
	for y in GRID:
		for x in GRID:
			var at:=_ground_bounds.position+Vector2(x,y)/float(GRID-1)*_ground_bounds.size
			var h:=float(_terrain.call("_height_at",origin.x+at.x,origin.z+at.y))-base if sampled else 0.0
			_heights[y*GRID+x]=h if is_finite(h) else 0.0

func _height(at:Vector2)->float:
	if _heights.is_empty():return 0.0
	var cell:Vector2=((at-_ground_bounds.position)/_ground_bounds.size*float(GRID-1)).clamp(Vector2.ZERO,Vector2.ONE*(GRID-1))
	var x:=mini(floori(cell.x),GRID-2);var y:=mini(floori(cell.y),GRID-2)
	var u:=cell.x-x;var v:=cell.y-y
	var a:=float(_heights[y*GRID+x]);var b:=float(_heights[y*GRID+x+1])
	var c:=float(_heights[(y+1)*GRID+x+1]);var d:=float(_heights[(y+1)*GRID+x])
	return a+(b-a)*u+(c-b)*v if u>=v else a+(c-d)*u+(d-a)*v

func _point(at:Vector2,lift:float=0.0)->Vector3:return Vector3(at.x,_height(at)+lift,at.y)

func _normal(at:Vector2)->Vector3:
	var step:=maxf(.0001,_ground_bounds.size.x/float(GRID-1))
	return Vector3(_height(at-Vector2(step,0))-_height(at+Vector2(step,0)),step*2.0,_height(at-Vector2(0,step))-_height(at+Vector2(0,step))).normalized()

func _landscape()->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in GRID-1:
		for x in GRID-1:
			var points:Array[Vector2]=[]
			for offset:Vector2 in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
				points.append(_ground_bounds.position+(Vector2(x,y)+offset)/float(GRID-1)*_ground_bounds.size)
			for face:Array in [[0,1,2],[0,2,3]]:
				for index:int in face:
					surface.set_normal(_normal(points[index]));surface.set_uv(points[index]*25.0);surface.add_vertex(_point(points[index]))
	var landscape:=_commit(surface,"Landscape",false)
	var shader:=Shader.new();shader.code=GROUND_SHADER
	var paint:=ShaderMaterial.new();paint.shader=shader
	paint.set_shader_parameter("ground_photo",load("res://assets/terrain/temperate_ground_albedo_v1.png"))
	landscape.material_override=paint
	var ground:=SurfaceTool.new();ground.begin(Mesh.PRIMITIVE_TRIANGLES);var count:=0
	for plot:Dictionary in snapshot.plots:
		if String(plot.get("status","active"))=="reclaimed":continue
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		var use:=String(plot.get("land_use",""));var color:=Color("b5a789")
		# A water-service parcel is a well/draw point, never evidence of a pond.
		# The recorded water object is rendered by Ground; channels by Setting.
		if use not in ["field","pasture","dirty_industry"]:continue
		if use in ["field","pasture"]:color=Color("a5ad63") if float(plot.get("crop_cover",.5))>.2 else Color("a58f68")
		elif use in ["waste","dirty_industry"]:color=Color("968e77")
		elif String(plot.get("status",""))=="ruin":color=Color("817a69")
		count+=_polygon(ground,polygon,color,.00003)
		if use=="field":count+=_field_rows(ground,polygon,plot)
	for route:Dictionary in snapshot.routes:
		if not bool(route.get("active",true)):continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		var width:=maxf(.001,float(route.get("width_m",2.0))*.001)
		for i in range(1,points.size()):
			var side:Vector2=(points[i]-points[i-1]).normalized().orthogonal()*width*.5
			count+=_polygon(ground,PackedVector2Array([points[i-1]+side,points[i]+side,points[i]-side,points[i-1]-side]),Color("786b52"),.0001)
	if count>0:_commit(ground,"RecordedGroundAndRoutes",false)

func _field_rows(surface:SurfaceTool,polygon:PackedVector2Array,plot:Dictionary)->int:
	if polygon.size()<3:return 0
	var area:=Rect2(polygon[0],Vector2.ZERO)
	for point in polygon:area=area.expand(point)
	var count:=0;var green:=Color("798c4c") if float(plot.get("crop_cover",.5))>.2 else Color("9a805c")
	for row in range(1,mini(18,int(area.size.y/.002))):
		var y:=area.position.y+row*.002
		var strip:=PackedVector2Array([Vector2(area.position.x,y),Vector2(area.end.x,y),Vector2(area.end.x,y+.00045),Vector2(area.position.x,y+.00045)])
		for clipped in Geometry2D.intersect_polygons(polygon,strip):count+=_polygon(surface,clipped,green,.00008)
	return count

func _polygon(surface:SurfaceTool,points:PackedVector2Array,color:Color,lift:float)->int:
	if points.size()<3:return 0
	var indices:=Geometry2D.triangulate_polygon(points)
	for index in indices:surface.set_normal(_normal(points[index]));surface.set_color(color);surface.add_vertex(_point(points[index],lift))
	return indices.size()

func _commit(surface:SurfaceTool,label:String,transparent:bool)->MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=label;node.mesh=surface.commit()
	var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.vertex_color_is_srgb=true;material.roughness=1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	if transparent:material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;model.add_child(node)
	return node

func _workplace_props(plan:Dictionary)->void:
	var crafts:=Ground.known_crafts();var count:=0
	for plot:Dictionary in snapshot.plots:
		if count>=24:break
		if String(plot.get("status","active")) in ["vacant","ruin","reclaimed","under_construction"]:continue
		var form:=String(plot.get("form",""));var use:=String(plot.get("land_use",""))
		var at:Vector2=plot.get("centroid",Vector2.ZERO)
		if form=="open_hearth_yard" and at.length()<.005:
			_prop("hearth_ring",at,0)
			var fire:=MeshInstance3D.new();var cone:=CylinderMesh.new();cone.bottom_radius=.00065;cone.top_radius=0;cone.height=.0015;cone.radial_segments=7
			fire.mesh=cone;fire.position=_point(at,.00075)
			var glow:=StandardMaterial3D.new();glow.albedo_color=Color("ef9d48");glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			fire.material_override=glow;fire.name="RecordedHearthFlame";model.add_child(fire)
		if use!="workshop":continue
		var choices:Array[String]=["bench","woodpile"]
		if bool(crafts.pottery):choices.append("pots")
		if bool(crafts.hides):choices.append("hide_frame")
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		var slot:=0
		for kind in choices:
			for attempt in 16:
				var angle:=TAU*(attempt+slot*3)/16.0
				var place:=at+Vector2.from_angle(angle)*(.003+attempt*.00025)
				if polygon.size()>2 and not Geometry2D.is_point_in_polygon(place,polygon):continue
				var clear:=true
				for building:Dictionary in plan.get("buildings",[]):
					if place.distance_to(building.position)<float(building.get("radius",.003))+.0015:clear=false;break
				if not clear:continue
				_prop(kind,place,angle);count+=1;slot+=1;break

func _prop(kind:String,at:Vector2,yaw:float)->void:
	var mesh:Mesh=Shapes.prop(kind)
	if mesh==null:return
	var node:=MeshInstance3D.new();node.name="Workplace_"+kind;node.mesh=mesh
	node.transform=Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3.ONE*.001),_point(at,.0001))
	node.material_override=preload("res://scripts/settlement_ink.gd").material();model.add_child(node)

func _worked_yards(plan:Dictionary)->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);var count:=0
	var shade:=SurfaceTool.new();shade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for building:Dictionary in plan.get("buildings",[]):
		var at:Vector2=building.position;var radius:=float(building.get("radius",.0035))*1.4
		for i in 14:
			var a:=at+Vector2.from_angle(TAU*i/14.0)*radius
			var b:=at+Vector2.from_angle(TAU*(i+1)/14.0)*radius
			for point:Vector2 in [at,a,b]:
				surface.set_normal(_normal(point))
				surface.set_color(Color(.59,.52,.37,.65) if point==at else Color(.59,.52,.37,0))
				surface.add_vertex(_point(point,.00005));count+=1
		var center:=at+Vector2(radius*.55,radius*.45)
		for i in 16:
			var a:=center+Vector2.from_angle(TAU*i/16.0)*radius*1.5
			var b:=center+Vector2.from_angle(TAU*(i+1)/16.0)*radius*1.5
			for point:Vector2 in [center,a,b]:
				shade.set_color(Color(1,1,1,.60 if point==center else 0));shade.add_vertex(_point(point,.00022))
	if count>0:_commit(surface,"WornGroundAroundRecordedBuildings",true)
	if count>0:
		var shadows:=_commit(shade,"DrapedBuildingContactShadows",true)
		var shader:=Shader.new();shader.code=CONTACT_SHADER
		var paint:=ShaderMaterial.new();paint.shader=shader;shadows.material_override=paint

func _make_highlight(polygons:Array)->void:
	if is_instance_valid(_highlight):_highlight.free()
	if polygons.is_empty():return
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);var count:=0
	var width:=clampf(_desired_span/maxf(1.0,size.y)*1.5,.00005,.00018)
	# Only the parcel edge is marked. Subdivide it over the sampled terrain,
	# feathering outwards so the working ground keeps its original appearance.
	for polygon:PackedVector2Array in polygons:
		for index in polygon.size():
			var first:=polygon[index];var last:=polygon[(index+1)%polygon.size()]
			var pieces:=maxi(1,ceili(first.distance_to(last)/.002))
			var side:Vector2=(last-first).normalized().orthogonal()*width
			for piece in pieces:
				var a:=first.lerp(last,float(piece)/pieces);var b:=first.lerp(last,float(piece+1)/pieces)
				for direction in [-1,1]:
					var strip:=[a,b,b+side*direction,a+side*direction]
					for vertex in [0,1,2,0,2,3]:
						surface.set_normal(_normal(strip[vertex]));surface.set_color(Color(.94,.75,.48,.50 if vertex<2 else 0))
						surface.add_vertex(_point(strip[vertex],.0002));count+=1
	if count>0:_highlight=_commit(surface,"FocusedWorkGround",true)

func _update_people()->void:
	if not is_instance_valid(model):return
	var key:=hash([_context.get("population",GameState.population_total),_context.get("allocations",GameState.population_allocations)])
	if key==_people_key:return
	_people_key=key
	if is_instance_valid(_people):_people.free()
	_walks.clear();visual_people_count=0
	var routes:Array=[]
	for route:Dictionary in snapshot.routes:
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		if bool(route.get("active",true)) and points.size()>1:routes.append(points)
	if routes.is_empty():return
	var population:=maxi(0,int(_context.get("population",GameState.population_total)))
	visual_people_count=mini(MAX_PEOPLE,ceili(sqrt(float(population))*2.0))
	if visual_people_count==0:return
	var shader:=Shader.new();shader.code=Life.shader_code("person")
	_people_paint=ShaderMaterial.new();_people_paint.shader=shader
	# The People view explicitly requests bounded illustrative representatives.
	# Its private shader does not change the map's global no-people policy.
	_people_paint.set_shader_parameter("map_people_visible",true)
	_people_paint.set_shader_parameter("min_px",9.0);_people_paint.set_shader_parameter("max_swell",1.3)
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.use_custom_data=true;batch.mesh=Life.quad();batch.instance_count=visual_people_count
	_people=MultiMeshInstance3D.new();_people.name="RepresentativePeople";_people.multimesh=batch;_people.material_override=_people_paint;model.add_child(_people)
	_people.custom_aabb=AABB(Vector3(_ground_bounds.position.x,-.1,_ground_bounds.position.y),Vector3(_ground_bounds.size.x,.2,_ground_bounds.size.y))
	var colors:Array[Color]=[Color("e0c39b"),Color("a96d51"),Color("556e69"),Color("d1b073"),Color("6a6253")]
	for i in visual_people_count:
		var path:PackedVector2Array=routes[i%routes.size()]
		_walks.append({"path":path,"phase":fmod(i*.618,1.0),"speed":.00055+(i%5)*.00006})
		batch.set_instance_color(i,colors[i%colors.size()])
		batch.set_instance_custom_data(i,Color(fmod(i*.618,1.0),0,1 if i%4==0 else 0,.75))
	# A few members work at existing physical work areas. They are illustrative
	# representatives, not an additional allocation or individual simulation.
	var index:=0;var allocations:Dictionary=_context.get("allocations",GameState.population_allocations)
	for role:String in ["Crafting","Construction","Food","Logistics","Knowledge","Defense"]:
		if index>=mini(6,_walks.size()) or int(allocations.get(role,0))<=0 or not _zones.has(role):continue
		var zone:Dictionary=_zones[role]
		if not bool(zone.physical):continue
		var at:Vector2=zone.center;var safe:=false
		for attempt in 16:
			var candidate:=at+Vector2.from_angle(attempt*TAU/16)*(.0025+attempt*.0002)
			var blocked:=false
			for building:Dictionary in _building_plan.get("buildings",[]):
				if candidate.distance_to(building.position)<float(building.get("radius",.003))+.0005:blocked=true;break
			if not blocked:at=candidate;safe=true;break
		if not safe:continue
		_walks[index]["stationary"]=at
		var pose:=8 if role in ["Crafting","Construction"] else (1 if role=="Food" else (7 if role=="Defense" else 5))
		batch.set_instance_custom_data(index,Color(float(index)*.17,pose,0,.7));index+=1
	_move_people()

func _move_people()->void:
	if not is_instance_valid(_people):return
	_people_paint.set_shader_parameter("anim_clock",_elapsed)
	for i in _walks.size():
		var walk:Dictionary=_walks[i];var path:PackedVector2Array=walk.path;var length:=0.0
		if walk.has("stationary"):
			_people.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.001),_point(walk.stationary,.00005)));continue
		for p in range(1,path.size()):length+=path[p-1].distance_to(path[p])
		if length<=.00001:continue
		var distance:=pingpong(float(walk.phase)*length*2+_elapsed*float(walk.speed),length)
		var at:Vector2=path[0];var direction:=Vector2.DOWN
		for p in range(1,path.size()):
			var segment:=path[p-1].distance_to(path[p])
			if distance<=segment:at=path[p-1].lerp(path[p],distance/maxf(segment,.00001));direction=path[p]-path[p-1];break
			distance-=segment
		_people.multimesh.set_instance_transform(i,Transform3D(Basis(Vector3.UP,atan2(direction.x,direction.y)).scaled(Vector3.ONE*.001),_point(at,.00005)))

func _overview_span()->float:
	var aspect:=maxf(.5,size.x/maxf(1.0,size.y))
	# Frame the inhabited center closely; remote parcels remain available
	# through their role anchors and the reversible wheel zoom.
	var horizontal:=absf(cos(_yaw))*_bounds.size.x+absf(sin(_yaw))*_bounds.size.y
	var depth:=absf(sin(_yaw))*_bounds.size.x+absf(cos(_yaw))*_bounds.size.y
	return maxf(.036,maxf(horizontal/aspect,depth*sin(_pitch)) *.84)

func _resize_view()->void:
	if not is_instance_valid(view):return
	view.size=Vector2i(maxi(1,roundi(size.x)),maxi(1,roundi(size.y)))
	if focused_role.is_empty():_desired_span=_overview_span()
	_position_camera();_project_anchors()

func _position_camera()->void:
	if not is_instance_valid(camera):return
	camera.size=maxf(.015,_span)
	var offset:=Vector3(sin(_yaw)*cos(_pitch),sin(_pitch),cos(_yaw)*cos(_pitch))
	var distance:=maxf(.025,_span/(2.0*tan(deg_to_rad(camera.fov*.5))))
	camera.position=_target+offset*distance;camera.look_at(_target)
	for material in _materials:material.set_shader_parameter("pixel_km",camera.size/maxf(1.0,view.size.y))

func _project_anchors()->void:
	if not is_instance_valid(camera) or not camera.is_inside_tree():return
	_anchors.clear()
	for role:String in _zones:
		var at:Vector2=_zones[role].center
		_anchors[role]=camera.unproject_position(_point(at,.003))
	role_anchors_changed.emit(_anchors.duplicate())

func _process(delta:float)->void:
	if not is_visible_in_tree() or not is_instance_valid(model):return
	_elapsed+=minf(delta,.1)
	_target=_target.lerp(_desired_target,1.0-exp(-delta*7.0))
	_span=lerpf(_span,_desired_span,1.0-exp(-delta*7.0))
	_position_camera();_project_anchors();_move_people()
	if is_instance_valid(_yards):
		_yards.set_view(Vector2(_target.x,_target.z),_span)
		_yards.process_jobs(1200,4)
		if int(_yards.batch_updates)!=_yard_batches:
			_yard_batches=int(_yards.batch_updates);_private_paint(_yards)

func _visibility_changed()->void:
	if is_instance_valid(view):view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE if is_visible_in_tree() else SubViewport.UPDATE_DISABLED

func _input_view(event:InputEvent)->void:
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_RIGHT:
		_yaw-=event.relative.x*.006;_pitch=clampf(_pitch+event.relative.y*.004,.35,1.18);_dragged=true;accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:_desired_span=maxf(.025,_desired_span*.9);accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:_desired_span=minf(_overview_span()*1.8,_desired_span/ .9);accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			var best:="";var distance:=42.0
			for role:String in _anchors:
				var d:float=event.position.distance_to(_anchors[role])
				if d<distance:best=role;distance=d
			if not best.is_empty():role_selected.emit(best)

const GROUND_SHADER:="""shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D ground_photo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 at;
void vertex(){at=VERTEX;}
float grain(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 c=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(grain(c),grain(c+vec2(1,0)),f.x),mix(grain(c+vec2(0,1)),grain(c+vec2(1)),f.x),f.y);}
void fragment(){
vec3 photo=texture(ground_photo,UV).rgb;
float broad=noise(at.xz*30.0)*.7+noise(at.xz*120.0+vec2(6.1,2.8))*.3;
vec3 ground=mix(vec3(.35,.39,.24),vec3(.46,.46,.31),broad);
ALBEDO=ground*(.87+dot(photo,vec3(.2126,.7152,.0722))*.28);ROUGHNESS=1.0;
}
"""

const CONTACT_SHADER:="""shader_type spatial;
render_mode unshaded,blend_mul,depth_draw_never,cull_disabled,shadows_disabled;
void fragment(){ALBEDO=mix(vec3(1.0),vec3(.47,.49,.43),COLOR.a);}
"""
