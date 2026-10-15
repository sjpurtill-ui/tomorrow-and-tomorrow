extends Control
## An illustrated workforce: 100 persistent people, one per percentage point.
## All numbers come from the existing allocation/forecast authorities.
signal role_anchors_changed(anchors:Dictionary)
signal focus_changed(role:String)
signal role_selected(role:String)
const Snapshot=preload("res://scripts/hud/people_settlement_scene.gd")
const WorkWorld=preload("res://scripts/hud/people_work_world.gd")
const Cast=preload("res://scripts/hud/people_workforce_cast.gd")
const Life=preload("res://scripts/map_life_ink.gd")
const Costumes=preload("res://scripts/hud/people_settlement_costumes.gd")
const MAX_PEOPLE:=100
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
var _zones:Dictionary={}
var _anchors:Dictionary={}
var _materials:Array[ShaderMaterial]=[]
var _foliage_materials:Array[ShaderMaterial]=[]
var _foliage_cut:=0.0
var _painted_materials:Array[ShaderMaterial]=[]
var _annotation_objects:Array[MeshInstance3D]=[]
var _annotation_obstacles:Array[Rect2]=[]
var _bounds:=Rect2()
var _overview_focus:=Vector2.ZERO
var _target:=Vector3.ZERO
var _desired_target:=Vector3.ZERO
var _span:=.1
var _desired_span:=.1
var _yaw:=-.60
var _pitch:=.61
var _elapsed:=0.0
var _people:MultiMeshInstance3D
var _highlight:MeshInstance3D
var _dragged:=false
var _drag_button:=0
var _drag_origin:=Vector2.ZERO
var _manual_navigation:=false
var _people_paint:ShaderMaterial
var _people_key:=-1
var _cast=Cast.new()
var _workforce_preview:=false
var _workforce_weights:Dictionary={}

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
	focus_mode=Control.FOCUS_CLICK
	custom_minimum_size=Vector2(240,360);size_flags_horizontal=Control.SIZE_EXPAND_FILL
	picture=TextureRect.new();picture.name="LivingSettlement"
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_SCALE
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var finish:=ShaderMaterial.new();var finish_shader:=Shader.new();finish_shader.code=SCENE_FINISH;finish.shader=finish_shader
	picture.material=finish;add_child(picture)
	view=SubViewport.new();view.name="PeopleSettlementWorld";view.own_world_3d=true
	view.size=Vector2i(1024,640);view.gui_disable_input=true;view.msaa_3d=Viewport.MSAA_4X
	view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;add_child(view)
	picture.texture=view.get_texture()
	camera=Camera3D.new();camera.name="SettlementCamera";camera.projection=Camera3D.PROJECTION_PERSPECTIVE;camera.fov=42.0
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
	_ensure_view();_context=context.duplicate(false)
	var next:=Snapshot.snapshot(context);var key:=Snapshot.signature(next)
	if key!=_key or not is_instance_valid(model):
		snapshot=next;_key=key;_build_scene()
	_update_people()
	if not _workforce_preview:set_workforce(context.get("allocations",GameState.population_allocations))
	_resize_view()

func set_workforce(weights:Dictionary,preview:bool=false)->void:
	_workforce_weights=weights.duplicate(true);_workforce_preview=preview
	if _cast.people.is_empty():return
	_cast.set_weights(weights);_move_people()

func workforce_percentages()->Dictionary:return _cast.percentages.duplicate()

func workforce_people()->Array[Dictionary]:return _cast.population()

func _build_scene()->void:
	if is_instance_valid(model):model.free()
	_materials.clear();_foliage_materials.clear();_painted_materials.clear()
	_annotation_objects.clear();_annotation_obstacles.clear();_people=null;_highlight=null;_people_key=-1
	model=Node3D.new();model.name="IllustratedWorkforce";view.add_child(model)
	var landscape:Dictionary=WorkWorld.render(model,_point,{"snapshot":snapshot})
	_zones=landscape.zones;_bounds=landscape.bounds;_overview_focus=landscape.overview_center
	_annotation_objects.assign(landscape.annotation_objects);_private_paint(model)
	var slots:Dictionary={};var gates:Dictionary={}
	for role:String in Cast.ROLES:
		slots[role]=WorkWorld.work_positions(role,100);gates[role]=_zones[role].gate
	_cast.configure(slots,gates,WorkWorld.hub(),WorkWorld.path_for_transfer)
	if not _cast.initialized:_cast.set_weights(_context.get("allocations",GameState.population_allocations),false)
	geometry_builds+=1;_update_people()
	if _zones.has(focused_role):focus_role(focused_role)
	else:reset_view()
	_target=_desired_target;_span=_desired_span;_position_camera();_project_anchors()

func _private_paint(node:Node)->void:
	for child in node.get_children():
		if child is GeometryInstance3D and child.material_override is ShaderMaterial:
			var paint:ShaderMaterial=child.material_override.duplicate();child.material_override=paint
			_materials.append(paint)
			if bool(child.get_meta("foliage",false)):_foliage_materials.append(paint)
			if bool(child.get_meta("painted",false)):_painted_materials.append(paint)
		_private_paint(child)

func _point(at:Vector2,lift:float=0.0)->Vector3:return Vector3(at.x,lift,at.y)
func _normal(_at:Vector2)->Vector3:return Vector3.UP

func _update_people()->void:
	if not is_instance_valid(model):return
	var look:=_clothing_appearance()
	if not is_instance_valid(_people):
		var shader:=Shader.new();shader.code=Costumes.painterly_shader_code()
		_people_paint=ShaderMaterial.new();_people_paint.shader=shader
		_people_paint.set_shader_parameter("people_atlas",Costumes.atlas_texture())
		_people_paint.set_shader_parameter("people_frames",Costumes.atlas_layout())
		var uniforms:Dictionary=Costumes.cast_uniforms()
		for parameter:String in uniforms:_people_paint.set_shader_parameter(parameter,uniforms[parameter])
		_people_paint.set_shader_parameter("motion_phase_supplied",true)
		_people_paint.set_shader_parameter("map_people_visible",true)
		_people_paint.set_shader_parameter("min_px",9.0);_people_paint.set_shader_parameter("max_swell",1.3)
		var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.use_custom_data=true
		batch.mesh=Life.quad();batch.instance_count=MAX_PEOPLE
		_people=MultiMeshInstance3D.new();_people.name="HundredPeople";_people.multimesh=batch;_people.material_override=_people_paint;model.add_child(_people)
		_people.custom_aabb=AABB(Vector3(_bounds.position.x,-.1,_bounds.position.y),Vector3(_bounds.size.x,.2,_bounds.size.y))
		visual_people_count=MAX_PEOPLE
	if _people_key!=int(look.key):
		_people_key=int(look.key)
		for parameter:String in look.uniforms:_people_paint.set_shader_parameter(parameter,look.uniforms[parameter])
		var colors:Array[Color]=look.palette
		for i in MAX_PEOPLE:_people.multimesh.set_instance_color(i,colors[i%colors.size()])
	_move_people()

func _move_people()->void:
	if not is_instance_valid(_people):return
	_people_paint.set_shader_parameter("anim_clock",_elapsed)
	for person:Dictionary in _cast.people:
		var direction:Vector2=_cast.direction(person)
		var role_index:=Cast.ROLES.find(String(person.role))
		var pose:=0 if bool(person.moving) else (20 if role_index>=0 else 100)
		_people.multimesh.set_instance_transform(int(person.id),Transform3D(Basis(Vector3.UP,atan2(direction.x,direction.y)).scaled(Vector3.ONE*.0012),_point(person.position,.00005)))
		_people.multimesh.set_instance_custom_data(int(person.id),Color(fmod(float(person.id)*.618,1.0),pose,Costumes.instance_code(maxi(0,role_index),int(person.sex)),float(person.traveled)/.0018))

func _overview_span()->float:
	var aspect:=maxf(.5,size.x/maxf(1.0,size.y))
	return maxf(.088,.145/aspect)

func _process(delta:float)->void:
	if not is_visible_in_tree() or not is_instance_valid(model):return
	_elapsed+=minf(delta,.1);_cast.advance(minf(delta,.1))
	_target=_target.lerp(_desired_target,1.0-exp(-delta*7.0))
	_span=lerpf(_span,_desired_span,1.0-exp(-delta*7.0))
	_foliage_cut=lerpf(_foliage_cut,0.0 if focused_role.is_empty() else 1.0,1.0-exp(-delta*7.0))
	_position_camera();_project_anchors();_move_people()

func focus_role(role:String)->void:
	if not _zones.has(role):return
	_manual_navigation=false
	focused_role=role
	var zone:Dictionary=_zones[role];var at:Vector2=zone.center
	_desired_target=_point(at)
	_desired_span=float(zone.focus_span)
	_make_highlight(zone.polygons)
	focus_changed.emit(role)

func reset_view()->void:
	_manual_navigation=false;_drag_button=0;_dragged=false
	focused_role="";_desired_target=_point(_overview_focus,.001);_desired_span=_overview_span()
	if is_instance_valid(_highlight):_highlight.visible=false
	focus_changed.emit("")

func role_screen_positions()->Dictionary:return _anchors.duplicate()

func role_anchor_metadata()->Dictionary:
	var result:Dictionary={}
	for role:String in _zones:
		var zone:Dictionary=_zones[role];var at:Vector2=zone.center
		var point:=_point(at,.003)
		var screen_polygons:Array[PackedVector2Array]=[]
		for polygon:PackedVector2Array in zone.polygons:
			var projected:=PackedVector2Array()
			for vertex:Vector2 in polygon:projected.append(camera.unproject_position(_point(vertex,.0002)))
			screen_polygons.append(projected)
		result[role]={"polygons":screen_polygons,"position":_anchors.get(role,Vector2.ZERO),"visible":not camera.is_position_behind(point) and Rect2(Vector2.ZERO,size).has_point(_anchors.get(role,Vector2.ZERO)),"physical":zone.physical,"plot_ids":zone.plot_ids.duplicate(),"source":zone.source}
	return result

func annotation_obstacles()->Array[Rect2]:return _annotation_obstacles.duplicate()

func _clothing_appearance()->Dictionary:
	# Read the selected settlement's last issued-clothing report without entering
	# a resource scope or advancing clothing production. Missing evidence keeps
	# the basic wraps; knowing a technique alone never outfits every household.
	var clothing:Dictionary=GameState.household_clothing
	var population:=float(GameState.population_total)
	var id:=String(_context.get("settlement_id",""))
	var record:Dictionary=SettlementModel.settlement_record(id) if not id.is_empty() else {}
	if not record.is_empty():
		if not bool(record.get("primary",false)):clothing=record.get("local_resources",{}).get("household_clothing",{})
		if WorldSimulation.state==GameState:population=SettlementModel._settlement_population(record)
	var report:Dictionary=clothing.get("report",{})
	var coverage:=clampf(float(report.get("issued",0))/maxf(1,population),0,1)
	var evidence:Dictionary=_context.get("clothing_context",{"adoption":GameState.discovery_adoption,"coverage":coverage})
	return Costumes.appearance(_context.get("clothing_knowledge",GameState.known_discoveries),evidence)

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

func _commit(surface:SurfaceTool,label:String,transparent:bool)->MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=label;node.mesh=surface.commit()
	var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.vertex_color_is_srgb=true;material.roughness=1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	if transparent:material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.render_priority=-20
	node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;model.add_child(node)
	return node

func _resize_view()->void:
	if not is_instance_valid(view):return
	view.size=Vector2i(maxi(1,roundi(size.x)),maxi(1,roundi(size.y)))
	if focused_role.is_empty() and not _manual_navigation:_desired_span=_overview_span()
	_position_camera();_project_anchors()

func _position_camera()->void:
	if not is_instance_valid(camera):return
	camera.size=maxf(.015,_span)
	var offset:=Vector3(sin(_yaw)*cos(_pitch),sin(_pitch),cos(_yaw)*cos(_pitch))
	var distance:=maxf(.008,_span/(2.0*tan(deg_to_rad(camera.fov*.5))))
	camera.position=_target+offset*distance;camera.look_at(_target)
	for material in _materials:material.set_shader_parameter("pixel_km",camera.size/maxf(1.0,view.size.y))
	for material in _painted_materials:material.set_shader_parameter("anim_clock",_elapsed)
	for material in _foliage_materials:
		material.set_shader_parameter("focus_world",_desired_target+Vector3.UP*.0015)
		material.set_shader_parameter("focus_radius",_desired_span*.19)
		material.set_shader_parameter("focus_cutaway",_foliage_cut)

func _project_anchors()->void:
	if not is_instance_valid(camera) or not camera.is_inside_tree():return
	_anchors.clear()
	for role:String in _zones:
		var at:Vector2=_zones[role].center
		_anchors[role]=camera.unproject_position(_point(at,.003))
	_annotation_obstacles.clear()
	var screen:=Rect2(Vector2.ZERO,size)
	for object:MeshInstance3D in _annotation_objects:
		if not is_instance_valid(object) or camera.is_position_behind(object.global_position):continue
		var illustrated:Vector2=object.get_meta("illustrated_size",Vector2.ZERO)
		var base:=object.global_position;var side:=camera.global_basis.x*illustrated.x*.5
		var up:=camera.global_basis.y*illustrated.y
		var rectangle:=Rect2(camera.unproject_position(base-side),Vector2.ZERO)
		for point:Vector3 in [base+side,base-side+up,base+side+up]:rectangle=rectangle.expand(camera.unproject_position(point))
		if rectangle.intersects(screen) and rectangle.size.x>8:_annotation_obstacles.append(rectangle.intersection(screen))
	role_anchors_changed.emit(_anchors.duplicate())

func _visibility_changed()->void:
	if is_instance_valid(view):view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE if is_visible_in_tree() else SubViewport.UPDATE_DISABLED

func _input_view(event:InputEvent)->void:
	if event is InputEventMouseMotion and _drag_button!=0:
		var mask:=MOUSE_BUTTON_MASK_LEFT if _drag_button==MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
		if not event.button_mask&mask:_drag_button=0;return
		if event.position.distance_to(_drag_origin)>5:_dragged=true
		if _dragged:pan_view(event.relative)
		accept_event()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_view(.88 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/.88,event.position);accept_event()
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			if event.pressed:
				_drag_button=event.button_index;_drag_origin=event.position;_dragged=false;grab_focus()
			else:
				var select:=_drag_button==MOUSE_BUTTON_LEFT and not _dragged
				_drag_button=0
				if select:_select_area_at(event.position)
			accept_event()
	elif event is InputEventPanGesture:
		pan_view(-event.delta*20.0);accept_event()
	elif event is InputEventMagnifyGesture:
		zoom_view(1.0/maxf(.1,event.factor),event.position);accept_event()
	elif event is InputEventKey and event.pressed:
		var shifts:={KEY_LEFT:Vector2(60,0),KEY_RIGHT:Vector2(-60,0),KEY_UP:Vector2(0,60),KEY_DOWN:Vector2(0,-60)}
		if shifts.has(event.keycode):pan_view(shifts[event.keycode]);accept_event()
		elif event.keycode in [KEY_PLUS,KEY_EQUAL,KEY_KP_ADD]:zoom_view(.88);accept_event()
		elif event.keycode in [KEY_MINUS,KEY_KP_SUBTRACT]:zoom_view(1.0/.88);accept_event()
		elif event.keycode==KEY_HOME:reset_navigation();accept_event()

## Artwork is painted from a fixed angle. Navigation moves over the ground;
## it never rotates or tilts the picture into stretched cardboard silhouettes.

func pan_view(pixels:Vector2)->void:
	if not is_instance_valid(camera) or size.y<1:return
	var center:=size*.5
	var before:=_navigation_ground(center)
	var after:=_navigation_ground(center+pixels)
	_desired_target+=before-after
	_clamp_navigation();_manual_navigation=true

func zoom_view(factor:float,at:Vector2=Vector2(-1,-1))->void:
	if not is_instance_valid(camera):return
	var next:=clampf(_desired_span*factor,.012,maxf(.031,_overview_span()*1.8))
	if at.x<0:at=size*.5
	var ground:=_navigation_ground(at)
	var ratio:=next/maxf(.0001,_desired_span)
	_desired_target=ground+(_desired_target-ground)*ratio
	_desired_span=next;_clamp_navigation();_manual_navigation=true

func reset_navigation()->void:
	if focused_role.is_empty():reset_view()
	else:focus_role(focused_role)

func _navigation_ground(at:Vector2)->Vector3:
	var plane:=Plane(Vector3.UP,_target.y)
	var hit:Variant=plane.intersects_ray(camera.project_ray_origin(at),camera.project_ray_normal(at))
	return hit if hit is Vector3 else _target

func _clamp_navigation()->void:
	var reach:=_bounds.grow(_desired_span*.25)
	var ground:=Vector2(clampf(_desired_target.x,reach.position.x,reach.end.x),clampf(_desired_target.z,reach.position.y,reach.end.y))
	_desired_target=_point(ground,.001)

func _select_area_at(at:Vector2)->void:
	var best:="";var distance:=42.0
	# The visible work area is clickable, not just its invisible center point.
	# Only dedicated parcels qualify; shared ground keeps the explicit labels.
	var metadata:=role_anchor_metadata()
	for role:String in metadata:
		if not bool(metadata[role].physical):continue
		for polygon:PackedVector2Array in metadata[role].polygons:
			if Geometry2D.is_point_in_polygon(at,polygon):role_selected.emit(role);return
	for role:String in _anchors:
		var separation:float=at.distance_to(_anchors[role])
		if separation<distance:best=role;distance=separation
	if not best.is_empty():role_selected.emit(best)

const SCENE_FINISH:="""shader_type canvas_item;
void fragment(){
vec4 scene=texture(TEXTURE,UV);
vec2 edge=(UV-.5)*vec2(.9,1.0);
float vignette=1.0-smoothstep(.28,.72,length(edge))*.12;
COLOR=vec4(scene.rgb*vignette,scene.a);
}
"""
