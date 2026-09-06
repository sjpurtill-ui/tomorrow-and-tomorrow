extends Node3D
## Camera onto the live world's existing geometry; no city reconstruction.
var terrain:Node
var camera:Camera3D
var target:=Vector3.ZERO
var center:=Vector3.ZERO
var zoom:=.24
var yaw:=.28
var elevation:=.75
var identity:=""
var snapshot:Dictionary={}

func _ready()->void:
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.near=.001;camera.far=2000;add_child(camera)

func configure(value:Dictionary)->void:
	snapshot=value
	if identity==String(value.id):return
	identity=String(value.id)
	var region:=String(value.get("region_id",""))
	CityEncounterWorld.focus(terrain,region)
	var report:Dictionary=CivilizationSystem.city_intelligence.known("player",region)
	center=GameState.settlement_founded_at
	if not report.is_empty():center=Vector3(float(report.position.x),0,float(report.position.z))
	center.y=terrain._close_surface_height_at(center.x,center.z)
	target=center;zoom=maxf(.18,terrain.camera.size)
	_update_camera()

func _update_camera()->void:
	camera.position=target+Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))*.5
	camera.look_at(target);camera.size=zoom

func focus(place:String)->void:
	target=center
	zoom=.28 if place=="overview" else .12
	if place=="gate":
		# Actual approaching army location, not an invented gate or siege ring.
		for army:Dictionary in MilitaryCampaign.field_armies:
			if String(army.get("status",""))=="besieging":
				var p:Variant=army.get("position",{})
				if p is Dictionary:target=Vector3(float(p.get("x",center.x)),center.y,float(p.get("z",center.z)))
	_update_camera()

func ground_at(point:Vector2)->Vector3:
	var origin:=camera.project_ray_origin(point);var direction:=camera.project_ray_normal(point)
	var hit:Variant=Plane(Vector3.UP,target.y).intersects_ray(origin,direction)
	return hit if hit is Vector3 else target

func navigate(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		if event.button_mask&MOUSE_BUTTON_MASK_LEFT:target+=ground_at(event.position-event.relative)-ground_at(event.position)
		if event.button_mask&MOUSE_BUTTON_MASK_RIGHT:yaw-=event.relative.x*.006;elevation=clampf(elevation+event.relative.y*.005,.3,1.3)
	elif event is InputEventMouseButton and event.pressed:
		var anchor:=ground_at(event.position)
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom=maxf(.035,zoom*.88)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom=minf(.8,zoom*1.12)
		_update_camera();target+=anchor-ground_at(event.position)
	_update_camera()
