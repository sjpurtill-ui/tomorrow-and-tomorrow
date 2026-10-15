extends RefCounted
## A representative working landscape. Scenery is illustrative, never a record
## of built structures, unlocked technologies, resource stocks or extra people.
const Art=preload("res://scripts/hud/people_settlement_art.gd")
const ROLES:Array[String]=["Food","Survey","Extraction","Construction","Crafting","Logistics","Knowledge","Administration","Defense"]
const RIGHT=Vector2(.8253356,.5646425)
const UP=Vector2(.5646425,-.8253356)
const SCENERY="res://assets/ui/people/work-world-sites-v1.png"
const GROUND="res://assets/ui/people/meadow-ground-v1.png"
const WELL="res://assets/ui/people/work-world-well-v1.png"
const LAYOUT={
	"Food":Vector2(-.040,-.031),"Survey":Vector2(-.043,.034),
	"Extraction":Vector2(.040,.035),"Construction":Vector2(.043,.002),
	"Crafting":Vector2(.002,.035),"Logistics":Vector2(.002,.001),
	"Knowledge":Vector2(-.037,.003),"Administration":Vector2(-.008,-.031),
	"Defense":Vector2(.034,-.032)}
const TITLES={"Food":"Fields & food","Survey":"Survey ground","Extraction":"Wood & stone","Construction":"Building","Crafting":"The workshop","Logistics":"Water & carrying","Knowledge":"Learning","Administration":"Keeping & caring","Defense":"Watch & training"}

static func world(at:Vector2)->Vector2:return RIGHT*at.x+UP*at.y

static func bounds()->Rect2:
	var result:=Rect2(world(Vector2(-.062,-.053)),Vector2.ZERO)
	for at:Vector2 in [Vector2(.065,-.053),Vector2(-.062,.060),Vector2(.065,.060)]:result=result.expand(world(at))
	return result

static func hub()->Vector2:return world(Vector2(.002,-.006))

static func zones()->Dictionary:
	var result:Dictionary={}
	for role:String in ROLES:
		var at:Vector2=LAYOUT[role];var center:=world(at);var polygon:=PackedVector2Array()
		for offset:Vector2 in [Vector2(-.012,-.011),Vector2(.010,-.011),Vector2(.013,-.005),Vector2(.012,.010),Vector2(.006,.017),Vector2(-.008,.017),Vector2(-.013,.008)]:polygon.append(world(at+offset))
		var area:=Rect2(polygon[0],Vector2.ZERO)
		for vertex:Vector2 in polygon:area=area.expand(vertex)
		result[role]={"center":center,"position":center,"polygon":polygon,"polygons":[polygon],"bounds":area,"work_area":Rect2(center-Vector2.ONE*.009,Vector2.ONE*.018),"focus_center":world(at+Vector2(0,.006)),"focus_span":.040,"title":TITLES[role],"physical":true,"source":"","plot_ids":[],"gate":world(at+Vector2(0,-.011)),"scenery":world(at+Vector2(.001,.015))}
	return result

static func work_positions(role:String,count:int=100)->PackedVector2Array:
	var result:=PackedVector2Array()
	if not LAYOUT.has(role):return result
	var center:Vector2=LAYOUT[role]
	# A stable sunflower packing fills outward, avoiding marching rows. The
	# first100slots always fit, even when every representative joins one role.
	for index in clampi(count,0,100):
		var slot:=(index*37)%100
		var angle:=float(slot)*2.39996323+float(ROLES.find(role))*.31
		var radius:=.00088*sqrt(float(slot)+.5)
		result.append(world(center+Vector2(cos(angle),sin(angle))*radius))
	return result

static func path_for_transfer(from_role:String,to_role:String)->PackedVector2Array:
	var data:=zones();var result:=PackedVector2Array()
	if not data.has(from_role) or not data.has(to_role):return result
	result.append_array(_route_to_hub(from_role))
	var arrival:=_route_to_hub(to_role);arrival.reverse();result.append_array(arrival)
	var clean:=PackedVector2Array()
	for at:Vector2 in result:
		if clean.is_empty() or clean[-1].distance_to(at)>.0001:clean.append(at)
	return clean

static func _route_to_hub(role:String)->PackedVector2Array:
	var at:Vector2=LAYOUT[role];var result:=PackedVector2Array([world(at+Vector2(0,-.011))])
	var aisle:=-.020 if at.x<-.010 else .020
	if at.y>.020:
		result.append(world(Vector2(at.x,.025)));result.append(world(Vector2(aisle,.025)));result.append(world(Vector2(aisle,-.006)))
	elif at.y<-.020:
		result.append(world(Vector2(at.x,-.049)));result.append(world(Vector2(aisle,-.049)));result.append(world(Vector2(aisle,-.006)))
	else:result.append(world(Vector2(at.x,-.006)))
	result.append(hub());return result

static func render(parent:Node3D,point:Callable,options:Dictionary={})->Dictionary:
	var data:=zones();var objects:Array[MeshInstance3D]=[];var obstacles:Array[Dictionary]=[]
	var root:=Node3D.new();root.name="RepresentativeWorkWorld";parent.add_child(root)
	_ground(root,point)
	var routes:Array[PackedVector2Array]=[]
	for role:String in ROLES:
		var path:=path_for_transfer(role,"Logistics");routes.append(path);_path(root,point,path,.0019,Color("a58e63"))
		var zone:Dictionary=data[role]
		_patch(root,point,zone.center,.0105,Color(.48,.42,.28,.20))
		var object:=_site(root,point,role,zone.scenery)
		if object!=null:
			objects.append(object)
			obstacles.append({"center":zone.scenery,"radius":.0048,"bounds":Rect2(Vector2(zone.scenery)-Vector2.ONE*.0048,Vector2.ONE*.0096),"role":role})
	_foliage(root,point,objects)
	var targets:Dictionary={}
	for role:String in ROLES:
		var entries:Array[Dictionary]=[]
		for at:Vector2 in work_positions(role,100):entries.append({"position":at,"stationary":at,"target":at+RIGHT*.0006,"direction":RIGHT,"pose":20,"role":role})
		targets[role]=entries
	return {"root":root,"zones":data,"bounds":bounds(),"routes":routes,"obstacles":obstacles,"targets":targets,"annotation_objects":objects,"hub":hub(),"overview_center":world(Vector2(0,.006)),"overview_span":.088,"representative":true,"options":options.duplicate(true)}

static func _site(parent:Node3D,point:Callable,role:String,at:Vector2)->MeshInstance3D:
	var cell:=-1;var width:=.013;var path:=SCENERY;var rows:=2;var columns:=3
	match role:
		"Food":cell=0;width=.017
		"Survey":cell=1;width=.015
		"Extraction":cell=2;width=.016
		"Knowledge":cell=3;width=.013
		"Administration":cell=4;width=.013
		"Defense":cell=5;width=.014
		"Construction":path=Art.STATES;cell=0;width=.015
		"Crafting":path=Art.BUILDINGS;cell=6;rows=3;columns=4;width=.016
		"Logistics":path=WELL;cell=0;rows=1;columns=1;width=.013
	if cell<0 or Art.atlas(path)==null:return null
	var node:=Art.sprite(parent,path,cell,point.call(at,.00005),width,{"rows":rows,"columns":columns,"name":"Worksite_"+role})
	if node!=null:node.set_meta("work_role",role)
	return node

static func _ground(parent:Node3D,point:Callable)->void:
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners:Array[Vector2]=[Vector2(-.65,-.65),Vector2(.65,-.65),Vector2(.65,.65),Vector2(-.65,.65)]
	for index in [0,1,2,0,2,3]:
		var at:=world(corners[index]);mesh.set_normal(Vector3.UP);mesh.set_uv(corners[index]*16.0);mesh.add_vertex(point.call(at,-.00002))
	var node:=MeshInstance3D.new();node.name="ContinuousWorkingLandscape";node.mesh=mesh.commit()
	var material:=ShaderMaterial.new();var shader:=Shader.new();shader.code=GROUND_SHADER;material.shader=shader;material.set_shader_parameter("ground_art",Art.atlas(GROUND));node.material_override=material;parent.add_child(node)

static func _path(parent:Node3D,point:Callable,path:PackedVector2Array,width:float,color:Color)->void:
	if path.size()<2:return
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(1,path.size()):
		var a:=path[index-1];var b:=path[index]
		if a.distance_to(b)<.0001:continue
		var side:Vector2=(b-a).normalized().orthogonal()*width*.5
		for edge:int in [-1,1]:
			var quad:Array[Vector2]=[a,b,b+side*edge,a+side*edge]
			for corner:int in [0,1,2,0,2,3]:
				surface.set_normal(Vector3.UP);surface.set_color(Color(color, .42 if corner<2 else 0.0));surface.add_vertex(point.call(quad[corner],.000025))
	_colored_mesh(parent,surface,"ConnectingFootpath")

static func _patch(parent:Node3D,point:Callable,center:Vector2,radius:float,color:Color)->void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 24:
		var a:=Vector2.from_angle(float(index)*TAU/24)*radius
		var b:=Vector2.from_angle(float(index+1)*TAU/24)*radius
		for vertex:int in 3:
			var offset:=Vector2.ZERO if vertex==0 else (a if vertex==1 else b)
			surface.set_normal(Vector3.UP);surface.set_color(Color(color,color.a if vertex==0 else 0.0));surface.add_vertex(point.call(center+offset,.000015))
	_colored_mesh(parent,surface,"OpenWorkingGround")

static func _colored_mesh(parent:Node3D,surface:SurfaceTool,label:String)->void:
	var node:=MeshInstance3D.new();node.name=label;node.mesh=surface.commit()
	var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node)

static func _foliage(parent:Node3D,point:Callable,objects:Array[MeshInstance3D])->void:
	for index in 18:
		var angle:=float(index)*TAU/18+.14
		var at:=world(Vector2(cos(angle)*.073,sin(angle)*.060+ .008))
		var node:=Art.sprite(parent,Art.DETAILS,index%2,point.call(at,.00002),.011+float(index%3)*.002,{"foliage":true,"sway":.00012,"phase":float(index),"name":"BorderTree_"+str(index)})
		if node!=null:objects.append(node)

const GROUND_SHADER="""
shader_type spatial;
render_mode unshaded,cull_disabled;
uniform sampler2D ground_art:source_color,filter_linear_mipmap,repeat_enable;
void fragment(){
 vec3 pigment=texture(ground_art,UV).rgb;
 float light=dot(pigment,vec3(.30,.55,.15));
 ALBEDO=mix(vec3(.33,.38,.21),pigment*.70+vec3(.13,.12,.075),.45);
}
"""
