extends VBoxContainer
## A dated report drawn with the map's building kits. Its private world contains
## only returned evidence and public topography, never a live foreign ledger.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Foreign:=preload("res://scripts/foreign_settlement_visual.gd")
const Drape:=preload("res://scripts/settlement_country_drape.gd")
const GRID_SIZE:=33
const MAX_YARDS:=128
var view:SubViewport
var camera:Camera3D
var model:Node3D
var picture:TextureRect
var caption:Label
var _reading:Label
var _control_note:Label
var _visit_button:Button
var _center_button:Button
var _whole_button:Button
var whole_town:=false
var frozen_report:Dictionary={}
var _geometry_key:Array=[]
var _terrain:Node
var _on_visit:Callable
var _origin:=Vector2.ZERO
var _heights:=PackedFloat32Array()
var _ground_width:=1.0
var _bounds:=AABB()
var _frame_points:=PackedVector3Array()
var _outline_materials:Array[ShaderMaterial]=[]
var _dirty:=true
var _render_pending:=false
var _viewport_updates:=0
var _model_builds:=0
var _height_samples:=0
var _ground_vertices:=0
var _startup_frames:=0

## Planning uncertainty grows with age; the town must stay as it was seen.
static func observed_report(source:Dictionary)->Dictionary:
	var report:=source.duplicate(true)
	var fields:Dictionary=report.get("fields",{})
	for key:String in fields:
		var field:Dictionary=fields[key]
		field["low"]=field.get("observed_low",field.get("low",0.0))
		field["high"]=field.get("observed_high",field.get("high",field.low))
	return report

func setup(block:Dictionary)->void:
	name="ReportedCityView";theme=T.control_theme()
	add_theme_constant_override("separation",9)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frozen_report=observed_report(block.get("report",{}))
	_terrain=block.get("terrain");_on_visit=block.get("on_visit",Callable())
	_geometry_key=_geometry_signature(frozen_report,_terrain)
	picture=TextureRect.new();picture.name="ReportedSettlement"
	picture.custom_minimum_size=Vector2(240,320)
	picture.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_SCALE
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(picture)
	view=SubViewport.new();view.name="ReportedCityWorld"
	view.own_world_3d=true;view.size=Vector2i(1200,800)
	view.gui_disable_input=true;view.msaa_3d=Viewport.MSAA_4X
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(view);picture.texture=view.get_texture()
	camera=Camera3D.new();camera.name="ReportCamera"
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true
	view.add_child(camera)
	_lighting()
	var framing:=HBoxContainer.new();framing.name="ReportFraming"
	framing.add_theme_constant_override("separation",8);add_child(framing)
	_center_button=Button.new();_center_button.name="TownCenter";_center_button.text="Town center"
	_center_button.toggle_mode=true;_center_button.set_pressed_no_signal(true)
	_center_button.pressed.connect(func()->void:set_whole_town(false));framing.add_child(_center_button)
	_whole_button=Button.new();_whole_button.name="WholeTown";_whole_button.text="Whole town"
	_whole_button.toggle_mode=true
	_whole_button.pressed.connect(func()->void:set_whole_town(true));framing.add_child(_whole_button)
	caption=T.make_label("",15,T.GOLD_TEXT)
	caption.name="ObservationCaption";caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_override("font",T.font("voice"));add_child(caption)
	_reading=T.make_label("",13,T.TEXT_SOFT)
	_reading.name="ReportReading";_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	add_child(_reading)
	_control_note=T.make_label("",13,T.TEXT_SOFT)
	_control_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(_control_note)
	_visit_button=Button.new();_visit_button.name="VisitReportedCity";_visit_button.text="Show on map ↗"
	_visit_button.flat=true;_visit_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	_visit_button.pressed.connect(func()->void:
		if _on_visit.is_valid():_on_visit.call())
	add_child(_visit_button)
	_update_words(block)
	_build_scene()
	picture.resized.connect(_resize_view)
	visibility_changed.connect(_visibility_changed)
	_bind_scroll.call_deferred();_resize_view.call_deferred()
	# Dock ancestors finish their clipping rectangles over several layout
	# passes. Retry this initial image briefly; settled portraits do no polling.
	_startup_frames=12;set_process(is_visible_in_tree())

func _process(_delta:float)->void:
	if not is_visible_in_tree() or not _dirty or _startup_frames<=0:
		set_process(false);return
	_startup_frames-=1
	if _on_screen():_resize_view();_request_render()

## A new date, source or widened uncertainty changes the words, not the town.
## The parent can replace this widget when actual observed geometry changes.
func update_block(block:Dictionary)->bool:
	var next:=observed_report(block.get("report",{}))
	var next_terrain:Node=block.get("terrain")
	if _geometry_signature(next,next_terrain)!=_geometry_key:return false
	frozen_report=next;_on_visit=block.get("on_visit",Callable())
	_update_words(block)
	return true

static func _geometry_signature(report:Dictionary,terrain:Node)->Array:
	var population:Dictionary=(report.get("fields",{}) as Dictionary).get("population",{})
	return [String(report.get("city_id","")),String(report.get("civ_id","")),report.get("position",{}),
		population.get("low",-1.0),population.get("high",-1.0),terrain.get_instance_id() if is_instance_valid(terrain) else 0]

func _update_words(block:Dictionary)->void:
	var words:Array[String]=[]
	var day:=int(frozen_report.get("observed_day",-1))
	words.append("Seen "+preload("res://scripts/calendar_date.gd").words(day) if day>=0 else "Observation date unknown")
	var status:=String(block.get("fresh_status",""));var age:=String(block.get("fresh_age",""))
	if not status.is_empty():words.append(status+(" · "+age if not age.is_empty() else ""))
	caption.text=" · ".join(words)
	_reading.text="A view from the returned report; the town may have changed since."
	if (frozen_report.get("fields",{}) as Dictionary).get("population",{}).is_empty():
		_reading.text="The town was located, but its population and buildings were not counted."
	var control_words:=String(block.get("caption",""))
	_control_note.text=control_words;_control_note.visible=not control_words.is_empty()
	_visit_button.visible=_on_visit.is_valid()

func _lighting()->void:
	var world:=WorldEnvironment.new();world.name="ReportDaylight"
	var environment:=Environment.new();world.environment=environment
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("b9c7c9")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("c5d5df");environment.ambient_light_energy=.24
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	view.add_child(world)
	var sun:=DirectionalLight3D.new();sun.name="AfternoonSun"
	sun.rotation_degrees=Vector3(-48,-38,0);sun.light_color=Color("fff0d5")
	sun.light_energy=.40;sun.shadow_enabled=true
	sun.directional_shadow_max_distance=4.0
	sun.shadow_bias=.025;sun.shadow_normal_bias=.25
	view.add_child(sun)

func _build_scene()->void:
	if frozen_report.is_empty():return
	var position:Dictionary=frozen_report.get("position",{})
	_origin=Vector2(float(position.get("x",0.0)),float(position.get("z",0.0)))
	# The existing report solver stays unchanged. It receives origin-local
	# coordinates so roofs and sub-metre ground detail keep floating precision.
	var local_report:=frozen_report.duplicate(true)
	local_report["position"]={"x":0.0,"z":0.0}
	_ground_width=maxf(.8,Foreign.framing_size(frozen_report)*4.0)
	_sample_ground()
	model=Foreign.new();model.name="ReportedCityFabric";view.add_child(model)
	model.build(local_report,func(x:float,z:float)->float:return _height(Vector2(x,z)),{},false)
	_model_builds+=1
	var ground_data:Dictionary=model.get_meta("report_ground",{})
	var plan:Dictionary=ground_data.get("plan",{"buildings":[]})
	_ground_mesh()
	_worked_ground(plan,ground_data.get("routes",[]))
	_bounds=AABB(Vector3(-.025,-.002,-.025),Vector3(.05,.014,.05))
	for child:Node in model.get_children():
		if not child is MultiMeshInstance3D or not String(child.name).begins_with("ForeignHouses_"):continue
		var batch:MultiMesh=child.multimesh
		var source_transforms:Array=child.get_meta("source_transforms",[])
		for index in batch.instance_count:
			var placed:Transform3D=source_transforms[index] if index<source_transforms.size() else batch.get_instance_transform(index)
			_bounds=_bounds.merge(placed*batch.mesh.get_aabb())
			for corner in 8:_frame_points.append(placed*batch.mesh.get_aabb().get_endpoint(corner))
		# The map's shared material receives live cloud/hearth uniforms. The
		# portrait gets its own frozen copy, including its own pixel outline.
		var source:Material=child.material_override
		if source is ShaderMaterial:
			var paint:ShaderMaterial=source.duplicate()
			paint.set_shader_parameter("map_cloud",Vector4.ZERO)
			paint.set_shader_parameter("map_wind",Vector4.ZERO)
			paint.set_shader_parameter("hearth",Vector4.ZERO)
			paint.set_shader_parameter("anim_clock",0.0)
			# The kit's authored paint is sRGB. Converting it once preserves
			# straw/earth detail under the portrait's natural scene lighting.
			paint.set_shader_parameter("vertex_srgb",true)
			if source.next_pass is ShaderMaterial:
				var outline:ShaderMaterial=source.next_pass.duplicate()
				outline.set_shader_parameter("outline_px",.75)
				paint.next_pass=outline;_outline_materials.append(outline)
			child.material_override=paint
	_frame()

func _sample_ground()->void:
	_heights.resize(GRID_SIZE*GRID_SIZE)
	var base:=0.0
	var sampled:=is_instance_valid(_terrain) and _terrain.has_method("_height_at")
	if sampled:base=float(_terrain.call("_height_at",_origin.x,_origin.y));_height_samples+=1
	for z in GRID_SIZE:
		for x in GRID_SIZE:
			var at:Vector2=(Vector2(x,z)/float(GRID_SIZE-1)-Vector2.ONE*.5)*_ground_width
			var value:=0.0
			if sampled:
				value=float(_terrain.call("_height_at",_origin.x+at.x,_origin.y+at.y))-base
				_height_samples+=1
			_heights[z*GRID_SIZE+x]=value if is_finite(value) else 0.0

## Piecewise affine sampling matches the ground mesh's alternating diagonals.
func _height(at:Vector2)->float:
	var cell:Vector2=(at/_ground_width+Vector2.ONE*.5)*float(GRID_SIZE-1)
	cell=cell.clamp(Vector2.ZERO,Vector2.ONE*float(GRID_SIZE-1))
	var x:=mini(floori(cell.x),GRID_SIZE-2);var z:=mini(floori(cell.y),GRID_SIZE-2)
	var u:=cell.x-x;var v:=cell.y-z
	var a:=float(_heights[z*GRID_SIZE+x]);var b:=float(_heights[z*GRID_SIZE+x+1])
	var c:=float(_heights[(z+1)*GRID_SIZE+x+1]);var d:=float(_heights[(z+1)*GRID_SIZE+x])
	if (x+z)%2==0:return a+(b-a)*u+(c-b)*v if u>=v else a+(c-d)*u+(d-a)*v
	return a+(b-a)*u+(d-a)*v if u+v<=1.0 else c+(d-c)*(1.0-u)+(b-c)*(1.0-v)

func _point(at:Vector2,lift:float=0.0)->Vector3:return Vector3(at.x,_height(at)+lift,at.y)

func _ground_mesh()->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in GRID_SIZE-1:
		for x in GRID_SIZE-1:
			var points:Array[Vector2]=[]
			for step:Vector2 in [Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN]:
				points.append(((Vector2(x,z)+step)/float(GRID_SIZE-1)-Vector2.ONE*.5)*_ground_width)
			var faces:Array=[[0,1,2],[0,2,3]] if (x+z)%2==0 else [[0,1,3],[2,3,1]]
			for face:Array in faces:
				for index:int in face:
					var point:Vector2=points[index]
					var step:=_ground_width/float(GRID_SIZE-1)
					var normal:=Vector3(_height(point-Vector2(step,0))-_height(point+Vector2(step,0)),step*2.0,
						_height(point-Vector2(0,step))-_height(point+Vector2(0,step))).normalized()
					surface.set_normal(normal);surface.set_uv(point*9.0)
					surface.add_vertex(_point(point));_ground_vertices+=1
	var node:=MeshInstance3D.new();node.name="ReportedLandscape";node.mesh=surface.commit()
	var material:=ShaderMaterial.new();var shader:=Shader.new()
	shader.code=GROUND_SHADER;material.shader=shader
	material.set_shader_parameter("ground_photo",load("res://assets/terrain/temperate_ground_albedo_v1.png"))
	node.material_override=material;view.add_child(node)

func _worked_ground(plan:Dictionary,routes:Array)->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var color:=Color("a19066");color.a=.72
	_disc(surface,Vector2.ZERO,.009,color)
	var count:=0
	for building:Dictionary in plan.get("buildings",[]):
		if count>=MAX_YARDS:break
		count+=1
		var at:Vector2=building.position
		_disc(surface,at,float(building.get("radius",.0035))*1.22,Color(.57,.51,.36,.45))
		var nearest:=Vector2.ZERO;var distance:=INF
		for route:Dictionary in routes:
			var path:PackedVector2Array=route.points
			for index in range(1,path.size()):
				var point:=Geometry2D.get_closest_point_to_segment(at,path[index-1],path[index])
				if point.distance_squared_to(at)<distance:nearest=point;distance=point.distance_squared_to(at)
		if distance<.0004:_ribbon(surface,at,nearest,.00075,color)
	for route:Dictionary in routes:
		var path:PackedVector2Array=route.points
		for index in range(1,path.size()):_ribbon(surface,path[index-1],path[index],.0016,color)
	var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.roughness=1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var node:=MeshInstance3D.new();node.name="ReportedPathsAndYards"
	node.mesh=surface.commit();node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;view.add_child(node)

func _disc(surface:SurfaceTool,at:Vector2,radius:float,color:Color)->void:
	for index in 10:
		_ground_triangle(surface,at,at+Vector2.from_angle(float(index)*TAU/10.0)*radius,at+Vector2.from_angle(float(index+1)*TAU/10.0)*radius,color)

func _ribbon(surface:SurfaceTool,a:Vector2,b:Vector2,width:float,color:Color)->void:
	if a.distance_squared_to(b)<.00000001:return
	var side:Vector2=(b-a).normalized().orthogonal()*width*.5
	_ground_triangle(surface,a-side,a+side,b+side,color)
	_ground_triangle(surface,a-side,b+side,b-side,color)

func _ground_triangle(surface:SurfaceTool,a:Vector2,b:Vector2,c:Vector2,color:Color)->void:
	for triangle:Array in Drape.split_triangle(a,b,c,color,color,color,Vector4(0,0,_ground_width,GRID_SIZE)):
		for index in [0,2,1]:
			var vertex:Dictionary=triangle[index]
			surface.set_color(vertex.color);surface.set_normal(Vector3.UP)
			surface.add_vertex(_point(vertex.point,.00006))

func _frame()->void:
	if camera==null:return
	var target:=_bounds.get_center()
	var distance:=maxf(.4,_bounds.size.length()*2.5)
	camera.position=target+Vector3(-.62,.82,1.0).normalized()*distance
	camera.look_at(target);camera.near=.0001;camera.far=maxf(3.0,distance*5.0)
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	var inverse:=camera.transform.affine_inverse()
	var points:=_frame_points
	if points.is_empty():
		for corner in 8:points.append(_bounds.get_endpoint(corner))
	for at:Vector3 in points:
		var point:Vector3=inverse*at
		low=low.min(Vector2(point.x,point.y));high=high.max(Vector2(point.x,point.y))
	# Fit actual roofs, not the empty corners of one large world-axis box.
	var middle:Vector2=(low+high)*.5
	camera.position+=camera.basis*Vector3(middle.x,middle.y,0.0)
	var aspect:=float(view.size.x)/float(maxi(1,view.size.y))
	var full_span:=maxf(.045,maxf(high.y-low.y,(high.x-low.x)/aspect)*1.12)
	camera.size=full_span*(1.0 if whole_town else .35)
	for material:ShaderMaterial in _outline_materials:material.set_shader_parameter("pixel_km",camera.size/float(maxi(1,view.size.y)))
	_request_render()

func set_whole_town(value:bool)->void:
	_center_button.set_pressed_no_signal(not value)
	_whole_button.set_pressed_no_signal(value)
	if whole_town==value:return
	whole_town=value;_frame()

func _resize_view()->void:
	if view==null:return
	var extent:=picture.size
	if extent.x<1.0 or extent.y<1.0:return
	var minimum_height:=240.0 if extent.x<420.0 else 320.0
	if not is_equal_approx(picture.custom_minimum_size.y,minimum_height):picture.custom_minimum_size.y=minimum_height
	var scale:=minf(2.0,minf(1440.0/extent.x,960.0/extent.y))
	var next:=Vector2i(maxi(2,roundi(extent.x*scale)),maxi(2,roundi(extent.y*scale)))
	if next==view.size:return
	view.size=next;_frame()

func _bind_scroll()->void:
	var ancestor:=get_parent()
	while ancestor!=null:
		if ancestor is Control:
			ancestor.resized.connect(_visibility_changed)
			ancestor.visibility_changed.connect(_visibility_changed)
		if ancestor is ScrollContainer:
			ancestor.get_v_scroll_bar().value_changed.connect(func(_value:float)->void:_visibility_changed())
			ancestor.get_h_scroll_bar().value_changed.connect(func(_value:float)->void:_visibility_changed())
		ancestor=ancestor.get_parent()

func _on_screen()->bool:
	if not is_visible_in_tree() or picture==null:return false
	var rect:=picture.get_global_rect();var ancestor:=get_parent()
	while ancestor!=null:
		if ancestor is Control and ancestor.clip_contents and not ancestor.get_global_rect().intersects(rect):return false
		ancestor=ancestor.get_parent()
	return true

func _visibility_changed()->void:
	if view==null:return
	if not is_visible_in_tree():
		view.render_target_update_mode=SubViewport.UPDATE_DISABLED;set_process(false)
	elif not _on_screen():view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	elif _dirty:_request_render()

func _request_render()->void:
	_dirty=true
	if view==null or not _on_screen() or _render_pending:return
	_render_pending=true;_render_once.call_deferred()

func _render_once()->void:
	_render_pending=false
	if view==null or not _on_screen():return
	_dirty=false;set_process(false)
	_viewport_updates+=1;view.render_target_update_mode=SubViewport.UPDATE_ONCE

func stats()->Dictionary:
	return {"model_builds":_model_builds,"building_count":int(model.get_meta("building_count",0)) if is_instance_valid(model) else 0,
		"viewport_updates":_viewport_updates,"height_samples":_height_samples,"ground_vertices":_ground_vertices,
		"representative":true,"whole_town":whole_town,"observed_day":int(frozen_report.get("observed_day",-1))}

const GROUND_SHADER:="""shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;
uniform sampler2D ground_photo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 at;
void vertex(){at=VERTEX;}
float grain(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
return mix(mix(grain(cell),grain(cell+vec2(1.0,0.0)),f.x),mix(grain(cell+vec2(0.0,1.0)),grain(cell+vec2(1.0)),f.x),f.y);
}
void fragment(){
vec3 photo=texture(ground_photo,UV).rgb;
vec3 crossed=texture(ground_photo,UV.yx*.71+vec2(.27,.41)).rgb;
float broad=noise(at.xz*12.0)*.7+noise(at.xz*34.0+vec2(6.1,2.8))*.3;
vec3 ground=mix(vec3(.26,.30,.22),vec3(.38,.39,.28),broad);
float texture_light=dot(mix(photo,crossed,.4),vec3(.2126,.7152,.0722));
ALBEDO=ground*(.84+texture_light*.34);
ROUGHNESS=1.0;
}
"""
