class_name BattleGeneral
extends Node3D

var figure:ArmyFigureFormation
var guards:ArmyFigureFormation
var label:Label3D
var standard:Node3D
var commander:Dictionary={}
var fate:="in command"
var elapsed:=0.0
var home:=Vector3.ZERO

func setup(data:Dictionary,color:Color)->void:
	commander=data.duplicate(true)
	figure=ArmyFigureFormation.new(); figure.figure_limit=1; add_child(figure)
	figure.configure({"cavalry":1},color)
	figure.scale=Vector3.ONE*1.3
	guards=ArmyFigureFormation.new(); guards.figure_limit=2; add_child(guards)
	guards.configure({"armored_foot":2},color,3.0); guards.position.z=-2.5
	standard=Node3D.new(); add_child(standard); standard.position=Vector3(1.8,0,0)
	var pole:=MeshInstance3D.new(); var cylinder:=CylinderMesh.new()
	cylinder.top_radius=.06; cylinder.bottom_radius=.09; cylinder.height=6
	pole.mesh=cylinder; pole.position.y=3; standard.add_child(pole)
	var gold:=StandardMaterial3D.new(); gold.albedo_color=Color("ffd16a"); gold.metallic=.5
	pole.material_override=gold
	var flag:=MeshInstance3D.new(); var cloth:=BoxMesh.new(); cloth.size=Vector3(2.2,1.3,.08)
	flag.mesh=cloth; flag.position=Vector3(1,5.2,0); flag.material_override=gold; standard.add_child(flag)
	label=Label3D.new(); label.font_size=32; label.pixel_size=.025; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test=true; label.modulate=Color("ffe3a0"); label.position=Vector3(0,7,0); add_child(label)
	_update_label()

func set_fate(value:String)->void:
	if value==fate: return
	fate=value; elapsed=0
	figure.set_animation("death" if fate=="killed" else ("walk" if "escaped" in fate or fate=="retreating" else "idle"),true)
	guards.set_animation("walk" if "escaped" in fate or fate=="retreating" else "idle",true)
	_update_label()

func _update_label()->void:
	label.text="GENERAL %s\n%s" % [String(commander.get("name","Unnamed")),fate.to_upper()]

func advance(delta:float,speed:float)->void:
	elapsed+=delta*speed
	figure.animation_speed=speed; guards.animation_speed=speed
	if "escaped" in fate or fate=="retreating":
		position=home+basis*Vector3(0,0,-minf(15,elapsed*(1.0 if "wounded" in fate else 2.5)))
		figure.rotation.y=PI; guards.rotation.y=PI
	elif fate=="killed":
		standard.rotation.z=lerpf(0,1.4,clampf(elapsed,0,1))
	elif fate=="captured":
		standard.rotation.z=.9

func details()->Dictionary:
	return {"general":true,"figure_id":commander.get("figure_id",""),"name":commander.get("name","Unnamed"),"fate":fate,"command":commander.get("command",.5),"tactics":commander.get("tactics",.5),"resolve":commander.get("resolve",.5)}
