extends Node3D
## Short-lived execution presentation. Owned and freed by CourtExecStage.
## World-space particles leave the moving wound/body; only new particles follow.
const FLAME:=preload("res://assets/court_sets/shaders/court_flame.gdshader")
var source:Node3D
var blood:Node3D
var drops:CPUParticles3D
var smoke:CPUParticles3D
var flames:Array[MeshInstance3D]=[]
var bones:Array[int]=[]
var skeleton:Skeleton3D
var elapsed:=0.0
var duration:=3.0
var landing_clock:=0.0
var burning:=false
var struggle:SkeletonModifier3D

class BurnStruggle extends SkeletonModifier3D:
	var elapsed:=0.0
	func _process_modification_with_delta(delta:float)->void:
		elapsed+=delta
		var sk:=get_skeleton()
		var strength:=smoothstep(0.0,0.3,elapsed)*(1.0-smoothstep(2.7,3.7,elapsed))
		if sk==null or strength<=0.0:return
		for bone_name:String in ["chest","head","upper_arm.L","upper_arm.R","forearm.L","forearm.R"]:
			var bone:=sk.find_bone(bone_name)
			if bone<0:continue
			var arm:=bone_name.contains("arm")
			var side:=-1.0 if bone_name.ends_with(".L") else 1.0
			var angle:=(0.6+sin(elapsed*8.0+float(bone)*1.7)*0.35)*side if arm else sin(elapsed*6.5+bone)*0.16
			var axis:=Vector3.FORWARD if arm else Vector3.RIGHT
			sk.set_bone_pose_rotation(bone,sk.get_bone_pose_rotation(bone)*Quaternion(axis,angle*strength))

func _exit_tree()->void:
	if is_instance_valid(struggle):struggle.queue_free()


func bleed(wound:Node3D,on_blood:Node3D)->void:
	name="WoundFlow";source=wound;blood=on_blood
	drops=CPUParticles3D.new();drops.name="WoundDrops"
	drops.amount=150;drops.lifetime=0.65;drops.local_coords=false
	drops.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
	drops.emission_sphere_radius=0.018;drops.spread=16.0
	drops.gravity=Vector3(0,-9.8,0)
	var mesh:=SphereMesh.new();mesh.radius=0.009;mesh.height=0.035;mesh.radial_segments=5;mesh.rings=3
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("690b0c");mat.roughness=0.28
	mesh.material=mat;drops.mesh=mesh;drops.scale_amount_min=0.5;drops.scale_amount_max=1.5
	add_child(drops)
	_update_wound(0.0)
	drops.emitting=true

func _update_wound(delta:float)->void:
	if not is_instance_valid(source):
		drops.emitting=false;set_process(false);return
	drops.global_position=source.global_position
	# The torso stump's local -Y points out through the cut. Never aim at the camera.
	var outward:=-source.global_basis.y.normalized()
	var pressure:=exp(-elapsed*1.7)
	drops.direction=(outward*pressure+Vector3.DOWN*(1.0-pressure)*0.75).normalized()
	drops.initial_velocity_min=0.15+1.65*pressure
	drops.initial_velocity_max=0.3+2.1*pressure
	drops.emitting=elapsed<duration
	landing_clock+=delta
	if landing_clock>=0.12 and elapsed<duration and is_instance_valid(blood):
		landing_clock=0.0
		var velocity:=drops.direction*drops.initial_velocity_max
		var at:=source.global_position
		var flight:=(velocity.y+sqrt(velocity.y*velocity.y+19.6*maxf(at.y,0.0)))/9.8
		var hit:=at+velocity*flight;hit.y=0.0
		blood.call("splat",hit,0.08+0.1*pressure,0.9,0.0,0.3)
	if elapsed>=duration:
		if is_instance_valid(blood):
			var at:=source.global_position;at.y=0.0
			blood.call("pool",at,0.36,2.2)
		set_process(false)

func burn(body:Node3D,seconds:float)->void:
	name="BodyFire";source=body;duration=seconds;burning=true
	skeleton=body.get("skeleton")
	struggle=BurnStruggle.new();struggle.name="BurnStruggle";skeleton.add_child(struggle)
	for bone_name:String in ["hips","chest","upper_arm.L","upper_arm.R","thigh.L","thigh.R"]:
		var bone:=skeleton.find_bone(bone_name)
		if bone<0:continue
		bones.append(bone)
		var card:=MeshInstance3D.new();card.name="BodyFlame"
		var quad:=QuadMesh.new();quad.size=Vector2.ONE;card.mesh=quad
		var mat:=ShaderMaterial.new();mat.shader=FLAME
		mat.set_shader_parameter("seed",float(bone)*2.37)
		mat.set_shader_parameter("speed",1.4);mat.set_shader_parameter("tongues",3)
		mat.set_shader_parameter("strength",0.8)
		card.material_override=mat;card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(card);flames.append(card)
	smoke=CPUParticles3D.new();smoke.name="BodySmoke";smoke.amount=38;smoke.lifetime=2.2
	smoke.local_coords=false;smoke.direction=Vector3.UP;smoke.spread=24.0
	smoke.gravity=Vector3(0.12,0.15,0);smoke.initial_velocity_min=0.5;smoke.initial_velocity_max=0.9
	smoke.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE;smoke.emission_sphere_radius=0.2
	var mesh:=QuadMesh.new();mesh.size=Vector2(0.55,0.55)
	var mat:=StandardMaterial3D.new();mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	var img:=Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var r:=Vector2(x-15.5,y-15.5).length()/15.5
			img.set_pixel(x,y,Color(0.12,0.11,0.10,pow(maxf(0.0,1.0-r),2.0)*0.45))
	mat.albedo_texture=ImageTexture.create_from_image(img);mesh.material=mat;smoke.mesh=mesh
	var gradient:=Gradient.new();gradient.set_color(0,Color(1,1,1,0));gradient.set_color(1,Color(1,1,1,0))
	gradient.add_point(0.15,Color.WHITE);gradient.add_point(0.6,Color(1,1,1,0.6));smoke.color_ramp=gradient
	smoke.scale_amount_min=0.8;smoke.scale_amount_max=2.2
	add_child(smoke);smoke.emitting=true
	_update_fire()

func _update_fire()->void:
	if not is_instance_valid(source) or not is_instance_valid(skeleton):
		queue_free();return
	var strength:=smoothstep(0.0,0.6,elapsed)*(1.0-smoothstep(duration-3.0,duration,elapsed)*0.88)
	for i in flames.size():
		var at:=skeleton.global_transform*skeleton.get_bone_global_pose(bones[i]).origin
		var height:=0.35+1.15*strength
		flames[i].global_position=at+Vector3.UP*height*0.4
		flames[i].scale=Vector3(0.35+0.3*strength,height,1)
		(flames[i].material_override as ShaderMaterial).set_shader_parameter("strength",strength*0.85)
	var chest:=skeleton.find_bone("chest")
	smoke.global_position=skeleton.global_transform*skeleton.get_bone_global_pose(chest).origin
	if elapsed>=duration:
		smoke.emitting=false
		for card in flames:card.hide()
		set_process(false)

func _process(delta:float)->void:
	elapsed+=delta
	if burning:_update_fire()
	elif drops!=null:_update_wound(delta)
