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
	set_meta("representative_layout",true)
	var lanes:=SurfaceTool.new();lanes.begin(Mesh.PRIMITIVE_TRIANGLES);surfaces["EarthAndLanes"]=lanes
	var rng:=RandomNumberGenerator.new();rng.seed=hash(String(report.city_id))^WorldSimulation.state.world_seed
	var heading:=rng.randf_range(-PI,PI)
	var plan:Dictionary={"buildings":[],"replaced":{}}
	var courts:=ceili(float(building_count)/4.0)
	var columns:=ceili(sqrt(float(courts)))
	var rows:=ceili(float(courts)/columns)
	var centers:Array[Vector2]=[]
	for court in courts:
		var center:=Vector2((court%columns-(columns-1)*.5)*.038,(court/columns-(rows-1)*.5)*.038)
		center+=Vector2(rng.randf_range(-.002,.002),rng.randf_range(-.002,.002))
		center=center.rotated(heading);centers.append(center)
		if court>0:
			var previous:=court-columns if court>=columns else court-1
			_lane(centers[previous],center,.0011,Color("84745c"))
		for slot in mini(4,building_count-court*4):
			var direction:=Vector2.from_angle(heading+float(slot)*TAU/4+PI/4)
			var local:=center+direction*.011
			footprint_radius=maxf(footprint_radius,local.length()+.006)
			var forward:=-direction
			plan.buildings.append({"position":local,"angle":atan2(forward.x,forward.y),"variant":(court+slot)%4,"plot":{}})
			# Doors share a court; no parcel mats or cross-street ladder paths.
			_lane(center,local-direction*.0045,.00065,Color("91836b"))
	# Shared authored assets, at their physical scale. These are representative
	# households, not fabricated foreign construction records or a hidden census.
	preload("res://scripts/organic_town_visual.gd").render(plan,Vector3.ZERO,func(x:float,z:float)->float:return _height(Vector2(x,z)),self)
	# Buildings and earth are batched, with no per-resident nodes or gameplay state.
	for key:String in surfaces:
		var surface:SurfaceTool=surfaces[key];surface.generate_normals()
		var instance:=MeshInstance3D.new();instance.name=key;instance.mesh=surface.commit()
		var material:=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
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
	for edge:int in [-1,1]:
		var inner_a:=a+side*edge;var inner_b:=b+side*edge
		var outer_a:=a+side*edge*1.8;var outer_b:=b+side*edge*1.8
		var points_fade:Array[Vector2]=[inner_a,inner_b,outer_b,inner_a,outer_b,outer_a]
		for index in 6:
			var p:=points_fade[index]
			var tint:=color;tint.a=0.0 if index in [2,4,5] else 1.0
			surfaces.EarthAndLanes.set_color(tint);surfaces.EarthAndLanes.add_vertex(Vector3(p.x,_height(p)+.0016,p.y))
