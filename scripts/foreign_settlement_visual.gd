extends Node3D
## Render-only settlement fabric. Identity/location come from returned evidence;
## unknown demographics and architecture never query a hidden civilization.
const MAX_BUILDINGS:=128
var building_count:=0
var footprint_radius:=.065
var ground:Callable
var origin:=Vector2.ZERO
var surfaces:Dictionary={}
static func display_population(report:Dictionary)->int:
	var estimate:Dictionary=report.get("fields",{}).get("population",{})
	return roundi((float(estimate.low)+float(estimate.high))*.5) if not estimate.is_empty() else -1
static func stable_population(report:Dictionary,previous:int)->int:
	var estimate:Dictionary=report.get("fields",{}).get("population",{})
	# Repeated lookout estimates vary. Keep the existing visual representation
	# while the new evidence still supports it; this is not a demographic census.
	if previous>=0 and not estimate.is_empty() and previous>=float(estimate.low) and previous<=float(estimate.high):return previous
	return display_population(report)
static func framing_size(report:Dictionary)->float:
	var population:=display_population(report)
	return clampf(.22+sqrt(maxf(0,population))*.0015,.22,.8)
func build(report:Dictionary,height_at:Callable)->void:
	ground=height_at;origin=Vector2(float(report.position.x),float(report.position.z))
	position=Vector3(origin.x,0,origin.y)
	set_meta("city_id",String(report.city_id));set_meta("details_confirmed",not report.get("fields",{}).is_empty())
	var population:=display_population(report)
	building_count=clampi(roundi(sqrt(float(population))*1.6),12,MAX_BUILDINGS) if population>=0 else 28
	footprint_radius=framing_size(report)*.27
	for key in ["EarthAndLanes","WallsAndTimber","PitchedRoofs"]:
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);surfaces[key]=surface
	var rng:=RandomNumberGenerator.new();rng.seed=hash(String(report.city_id))^GameState.world_seed
	var main_axis:=rng.randf_range(-.6,.6)
	var road:Array[Vector2]=[]
	for i in 17:
		var t:=float(i)/16.0
		road.append(Vector2(sin(t*5.0)*footprint_radius*.13,(t-.5)*footprint_radius*2.25).rotated(main_axis))
	for i in range(1,road.size()):_lane(road[i-1],road[i],.0032,Color("84745c"))
	for i in building_count:
		var rows:=ceili(float(building_count)/2)
		var t:float=(float(i/2)+.5)/maxf(1,rows)
		var side:float=-1 if i%2==0 else 1
		var core:=Vector2(sin(t*5.0)*footprint_radius*.13,(t-.5)*footprint_radius*1.95)
		var lateral:=.014+rng.randf_range(0,.014)+(float(i%3)*.005 if building_count>50 else 0.0)
		var local:Vector2=(core+Vector2(side*lateral,rng.randf_range(-.002,.002))).rotated(main_axis)
		var angle:=main_axis+rng.randf_range(-.28,.28)
		var width:=rng.randf_range(.005,.008);var depth:=rng.randf_range(.007,.011)
		_lane(core.rotated(main_axis),local,.0013,Color("91836b"))
		_yard(local,Vector2(width*1.5,depth*1.25),angle,Color("8b8167"))
		_house(local,width,depth,rng.randf_range(.0028,.0042),angle,rng)
	# Buildings and earth are batched, with no per-resident nodes or gameplay state.
	for key:String in surfaces:
		var surface:SurfaceTool=surfaces[key];surface.generate_normals()
		var instance:=MeshInstance3D.new();instance.name=key;instance.mesh=surface.commit()
		var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true
		material.roughness=.94;material.cull_mode=BaseMaterial3D.CULL_DISABLED
		instance.material_override=material;add_child(instance)
	set_meta("building_count",building_count)
func _height(p:Vector2)->float:return float(ground.call(origin.x+p.x,origin.y+p.y))
func _tri(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,color:Color)->void:
	for v in [a,b,c]:surface.set_color(color);surface.add_vertex(v)
func _quad(surface:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,color:Color)->void:
	_tri(surface,a,b,c,color);_tri(surface,a,c,d,color)
func _lane(a:Vector2,b:Vector2,width:float,color:Color)->void:
	var side:=(b-a).normalized().orthogonal()*width*.5
	var points:Array[Vector2]=[a-side,a+side,b+side,b-side]
	var corners:Array[Vector3]=[]
	for p in points:corners.append(Vector3(p.x,_height(p)+.0016,p.y))
	_quad(surfaces.EarthAndLanes,corners[0],corners[1],corners[2],corners[3],color)
func _yard(center:Vector2,size_value:Vector2,angle:float,color:Color)->void:
	var corners:Array[Vector3]=[]
	for offset in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		var p:Vector2=center+(offset*size_value*.5).rotated(angle)
		corners.append(Vector3(p.x,_height(p)+.0015,p.y))
	_quad(surfaces.EarthAndLanes,corners[0],corners[1],corners[2],corners[3],color)
func _point(center:Vector2,x:float,z:float,y:float,angle:float)->Vector3:
	var p:=center+Vector2(x,z).rotated(angle);return Vector3(p.x,y,p.y)
func _house(center:Vector2,width:float,depth:float,height:float,angle:float,rng:RandomNumberGenerator)->void:
	var base:=_height(center)+.0018
	var h:=base+height;var peak:=h+width*.35
	var w:=width*.5;var d:=depth*.5
	var walls:SurfaceTool=surfaces.WallsAndTimber;var roofs:SurfaceTool=surfaces.PitchedRoofs
	var color:=Color("b3a083").darkened(rng.randf_range(0,.22))
	var roof:=Color("897348").darkened(rng.randf_range(0,.23))
	var corners:Array[Vector2]=[Vector2(-w,-d),Vector2(w,-d),Vector2(w,d),Vector2(-w,d)]
	for i in 4:
		var a:Vector2=corners[i];var b:Vector2=corners[(i+1)%4]
		_quad(walls,_point(center,a.x,a.y,base,angle),_point(center,b.x,b.y,base,angle),_point(center,b.x,b.y,h,angle),_point(center,a.x,a.y,h,angle),color)
	for z in [-d,d]:
		_tri(walls,_point(center,-w,z,h,angle),_point(center,w,z,h,angle),_point(center,0,z,peak,angle),color)
	for side in [-1,1]:
		_quad(roofs,_point(center,side*(w+.0006),-d-.0005,h-.0002,angle),_point(center,side*(w+.0006),d+.0005,h-.0002,angle),_point(center,0,d+.0005,peak,angle),_point(center,0,-d-.0005,peak,angle),roof)
		# Fine thatch courses make the roof readable at close aerial zoom.
		for course in range(1,7):
			var fraction:=float(course)/7
			var x:float=side*w*fraction;var y:=lerpf(peak,h,fraction)+.00004
			_quad(roofs,_point(center,x,-d,y,angle),_point(center,x,d,y,angle),_point(center,x+side*.00010,d,y-.00002,angle),_point(center,x+side*.00010,-d,y-.00002,angle),roof.darkened(.14))
	# Door and lintel are geometry, not another repeated city symbol.
	_quad(walls,_point(center,-.00065,-d-.00004,base,angle),_point(center,.00065,-d-.00004,base,angle),_point(center,.00065,-d-.00004,base+.0019,angle),_point(center,-.00065,-d-.00004,base+.0019,angle),Color("463d30"))
