extends Node3D
const FRONT=preload("res://scripts/army_front_visual.gd")
const MAX_BUILDINGS:=96
const MAX_FIGURES:=96
var camera:Camera3D
var city:Node3D
var units:Node3D
var radius:float=36
var yaw:float=.4
var elevation:float=.7
var zoom:float=100
var target:=Vector3.ZERO
var signature:String=""
var force_signature:String=""
var building_count:int=0
var figure_count:int=0
var active_animation:float=0
var figure_groups:Array=[]

func _ready()->void:
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("a9c5ca")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("d4dbcc");env.ambient_light_energy=.35
	world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0);sun.light_energy=.65;sun.shadow_enabled=true;add_child(sun)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.far=1000000;add_child(camera)
	city=Node3D.new();add_child(city);units=Node3D.new();add_child(units)
	_camera()

func _box(parent:Node3D,position:Vector3,size:Vector3,color:Color)->void:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;node.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=color;material.roughness=.95;node.material_override=material
	node.position=position;parent.add_child(node)

func configure(snapshot:Dictionary)->void:
	var key:="%s/%s/%s/%s" % [snapshot.id,snapshot.population,snapshot.defense_stage,snapshot.damage]
	if key!=signature:
		signature=key
		for child in city.get_children():child.free()
		var population:=maxf(0,float(snapshot.population))
		building_count=clampi(roundi(sqrt(population)*1.2),8,MAX_BUILDINGS) if population>0 else 12
		radius=28+minf(16,sqrt(float(building_count)))
		_box(city,Vector3(0,-.35,0),Vector3(1000,.5,1000),Color("64734f"))
		_box(city,Vector3(0,-.07,0),Vector3(radius*1.65,.15,radius*1.65),Color("a79e85"))
		for lane in [-1,0,1]:
			_box(city,Vector3(lane*12,.04,0),Vector3(3,.06,radius*2.2),Color("c6b99b"))
			_box(city,Vector3(0,.04,lane*12),Vector3(radius*2.2,.06,3),Color("c6b99b"))
		var rng:=RandomNumberGenerator.new();rng.seed=hash(String(snapshot.id))
		for i in building_count:
			var columns:=ceili(sqrt(float(building_count)))
			var column:=i%columns;var row:=i/columns
			var x:=(column-float(columns-1)*.5)*6.0;var z:=(row-float(columns-1)*.5)*6.0
			if absf(x)<2.0 or absf(z)<2.0 or Vector2(x,z).length()>radius-6:continue
			var ruined:=float(snapshot.damage)>rng.randf()
			var height:=.5 if ruined else rng.randf_range(2.0,4.5 if population<3000 else 7.0)
			var tint:=Color("807c6c") if ruined else Color("d3bb91").darkened(rng.randf_range(0,.15))
			_box(city,Vector3(x,height*.5,z),Vector3(4.0,height,4.1),tint)
			if not ruined:_box(city,Vector3(x,height+.25,z),Vector3(4.6,.65,4.8),Color("755344"))
		var stage:=int(snapshot.defense_stage)
		if stage>=2:
			var wall_color:=Color("76614b") if stage<4 else Color("a6a494")
			var height:=1.2 if stage==2 else (4.5 if stage==3 else 6.0)
			for sector in 48:
				if sector in [11,12]:continue
				var angle:=TAU*sector/48.0
				var segment:=Node3D.new();city.add_child(segment);segment.position=Vector3(cos(angle)*radius,0,sin(angle)*radius);segment.rotation.y=-angle
				_box(segment,Vector3(0,height*.5,0),Vector3(1.8,height,TAU*radius/48+.2),wall_color)
				if stage>=3 and sector%6==0:_box(segment,Vector3(0,height*.6,0),Vector3(3,height*1.2,3),wall_color.darkened(.1))
		elif stage==1:
			for angle in [0.0,PI*.5,PI,PI*1.5]:_box(city,Vector3(cos(angle)*radius,3,sin(angle)*radius),Vector3(2,6,2),Color("806647"))
	_update_forces(snapshot)

func _update_forces(snapshot:Dictionary)->void:
	var battle:Dictionary=snapshot.get("battle",{})
	var offensive:=String(snapshot.mode)=="offensive"
	var forces:Array=[battle.get("attacker",snapshot.own_force if offensive else {}),battle.get("defender",{} if offensive else snapshot.own_force)]
	var key:=JSON.stringify([forces,battle.get("termination",{}),radius])
	if key==force_signature:return
	force_signature=key
	# Aggregate siege deployment is schematic: blockade fractions are not locations.
	# Unknown defenders do not acquire invented soldiers, camps or occupied ground.
	if figure_groups.is_empty():
		for side in 2:
			var front:=FRONT.new();units.add_child(front);figure_groups.append(front)
	figure_count=0
	var span:=radius*2.5
	for side in 2:
		var front:ArmyFrontVisual=figure_groups[side]
		front.configure(FRONT.combat_force(forces[side],battle.get("termination",{})),Color("df805f") if side==0 else Color("63c3d0"),1,0,true)
		var depth:=0.0
		for section in front.sections:
			for point in section.polygon:
				span=maxf(span,absf(point.x)*2.5);depth=maxf(depth,absf(point.y))
		front.position=Vector3(0,0,(-1 if side==0 else 1)*(radius+depth+8))
	zoom=maxf(zoom,span);_camera()

func _camera()->void:
	camera.size=zoom;camera.position=target+Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))*maxf(180,zoom*1.2)
	camera.look_at(target,Vector3.UP)
func navigate(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom=maxf(25,zoom*.88)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom=minf(1000000,zoom/ .88)
	if event is InputEventMouseMotion:
		if event.button_mask&MOUSE_BUTTON_MASK_RIGHT:yaw-=event.relative.x*.006;elevation=clampf(elevation+event.relative.y*.005,.2,1.35)
		elif event.button_mask&MOUSE_BUTTON_MASK_LEFT:
			target+=(-camera.global_basis.x*event.relative.x+Vector3(camera.global_basis.z.x,0,camera.global_basis.z.z).normalized()*-event.relative.y)*zoom*.0015
			target.x=clampf(target.x,-90,90);target.z=clampf(target.z,-90,90)
	_camera()
func focus(where:String)->void:
	target=Vector3(0,0,-radius) if where=="gate" else Vector3.ZERO
	zoom=65 if where=="gate" else (75 if where=="city" else 100)
	_camera()
