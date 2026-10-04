extends Node3D
## The court's blood, for its executions: cartoon-bright and over the top
## (EXECUTIONS.md). It lives on the set (court_set_3d.gd blood()), is made on
## first use, and runs nothing when idle: pooled emitters that stop, a
## MultiMesh of splats that only changes when blood lands, stickers reused.
##   geyser(at, dir, seconds, power)      a fountain from a neck or a wound: a
##                                        pumping jet, drops off it, landing as
##                                        splats where they would fall
##   spray(from, targets, power)          an arc flung at the front row: splats
##                                        at their feet, stickers on them
##   splat(at, size, ...)                 one splat on the floor (or a wall)
##   pool(at, radius, seconds)            a pool spreading under a body
##   stain_figure(body, count)            stickers of blood on someone
##   mist(lens, seconds, around)          the red mist that paints the hall
##   stain(index, at, size, age_days)     the lasting stains (trophies), which
##                                        clear() leaves
##   clear()                              the floor and everyone wiped
## Presentation only. Gore settings (full / mild / off) are the director's:
## with gore off or mild it simply does not call these.

const SPLAT:=preload("res://assets/court_sets/shaders/court_blood_splat.gdshader")
const DROP:=preload("res://assets/court_sets/shaders/court_blood_drop.gdshader")
const MIST:=preload("res://assets/court_sets/shaders/court_mist.gdshader")
const JET:=preload("res://assets/court_sets/shaders/court_blood_jet.gdshader")

const SPLATS:=160
const STAINS:=12
const EMITTERS:=4
const STICKERS:=28
const GRAVITY:=9.8

var _mm:MultiMesh
var _mm_node:MultiMeshInstance3D
var _stain_mm:MultiMesh
var _stain_node:MultiMeshInstance3D
var _next:=0
var _emitters:Array[GPUParticles3D]=[]
var _next_emitter:=0
var _stickers:Array[MeshInstance3D]=[]
var _next_sticker:=0
var _splat_mat:ShaderMaterial
var _jets:Array[MeshInstance3D]=[]
var _next_jet:=0
const JETS:=2
var _mist:MeshInstance3D
var _mist_mat:ShaderMaterial
var rng:=RandomNumberGenerator.new()
## How many splats have landed since the last clear() (tests, the director).
var landed:=0
## Where each splat lies and how strong each lasting stain is, kept here (the
## MultiMesh is never read back from the renderer).
var spots:=PackedVector3Array()
var stain_alpha:=PackedFloat32Array()

func _init()->void:
	name="Blood"
	rng.seed=1931
	_splat_mat=ShaderMaterial.new();_splat_mat.shader=SPLAT
	_splat_mat.set_shader_parameter("ragged",ragged_noise())
	_mm=_make_mm(SPLATS)
	_mm_node=MultiMeshInstance3D.new();_mm_node.name="Splats";_mm_node.multimesh=_mm
	_mm_node.material_override=_splat_mat;_mm_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mm_node.extra_cull_margin=64.0
	add_child(_mm_node)
	_stain_mm=_make_mm(STAINS)
	_stain_node=MultiMeshInstance3D.new();_stain_node.name="Stains";_stain_node.multimesh=_stain_mm
	_stain_node.material_override=_splat_mat;_stain_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stain_node.extra_cull_margin=64.0
	add_child(_stain_node)
	for i in EMITTERS:_emitters.append(_make_emitter(i))
	var ribbon:=_ribbon(32)
	for i in JETS:
		var jet:=MeshInstance3D.new();jet.name="Jet%d" % i;jet.mesh=ribbon
		var jm:=ShaderMaterial.new();jm.shader=JET;jet.material_override=jm
		jet.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		jet.extra_cull_margin=8.0;jet.visible=false
		add_child(jet);_jets.append(jet)
	spots.resize(SPLATS);spots.fill(Vector3(0.0,-50.0,0.0))
	stain_alpha.resize(STAINS);stain_alpha.fill(0.0)
	set_process(false)

## The splats' rim wobble: a small tiling noise, made once.
static var _ragged:ImageTexture
static func ragged_noise()->ImageTexture:
	if _ragged==null:
		var noise:=FastNoiseLite.new();noise.seed=7;noise.frequency=0.09
		noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		var img:=Image.create(64,64,false,Image.FORMAT_L8)
		for y in 64:
			for x in 64:
				# tiling: blend the field with its own wrap
				var fx:=float(x)/64.0;var fy:=float(y)/64.0
				var a:=noise.get_noise_2d(x,y);var b:=noise.get_noise_2d(x-64,y)
				var c:=noise.get_noise_2d(x,y-64);var d:=noise.get_noise_2d(x-64,y-64)
				var v:=lerpf(lerpf(a,b,fx),lerpf(c,d,fx),fy)
				img.set_pixel(x,y,Color(0.5+0.9*v,0.5+0.9*v,0.5+0.9*v))
		_ragged=ImageTexture.create_from_image(img)
	return _ragged

func _make_mm(count:int)->MultiMesh:
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_custom_data=true
	var plane:=PlaneMesh.new();plane.size=Vector2(1.0,1.0)
	mm.mesh=plane
	mm.instance_count=count
	# none are drawn until blood lands (splat() raises it, clear() drops it)
	mm.visible_instance_count=0
	for i in count:
		mm.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3(0.001,0.001,0.001)),Vector3(0.0,-50.0,0.0)))
		mm.set_instance_custom_data(i,Color(0,0,0,0))
	return mm

## The jet's ribbon: a strip whose UV.y runs along the arc (the shader bends it).
static func _ribbon(segments:int)->ArrayMesh:
	var verts:=PackedVector3Array();var uvs:=PackedVector2Array();var index:=PackedInt32Array()
	for i in segments+1:
		var t:=float(i)/float(segments)
		for side in 2:
			verts.append(Vector3(float(side)-0.5,t,0.0));uvs.append(Vector2(float(side),t))
	for i in segments:
		var a:=i*2
		index.append_array([a,a+1,a+2,a+1,a+3,a+2])
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=index
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.custom_aabb=AABB(Vector3(-4,-3,-4),Vector3(8,8,8))
	return mesh

func _make_emitter(i:int)->GPUParticles3D:
	var e:=GPUParticles3D.new();e.name="Drops%d" % i
	e.amount=110;e.lifetime=1.9;e.local_coords=false;e.emitting=false
	var pm:=ParticleProcessMaterial.new()
	pm.direction=Vector3(0,1,0);pm.spread=14.0
	pm.initial_velocity_min=3.5;pm.initial_velocity_max=5.5
	pm.gravity=Vector3(0,-GRAVITY,0)
	pm.scale_min=0.45;pm.scale_max=1.5
	pm.particle_flag_align_y=true
	var life:=Gradient.new();life.set_color(0,Color(1,1,1,1));life.set_color(1,Color(1,1,1,1))
	life.add_point(0.85,Color(1,1,1,1))
	var tex:=GradientTexture1D.new();tex.gradient=life;pm.color_ramp=tex
	e.process_material=pm
	var quad:=QuadMesh.new();quad.size=Vector2(0.06,0.095)
	var mat:=ShaderMaterial.new();mat.shader=DROP;quad.material=mat
	e.draw_pass_1=quad
	e.visibility_aabb=AABB(Vector3(-6,-2,-6),Vector3(12,10,12))
	e.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(e)
	return e

# --- Splats -------------------------------------------------------------------------

## One splat lying on a surface (the floor unless normal says otherwise); it
## spreads out over a moment. Returns its index.
func splat(at:Vector3,size:=0.4,alpha:=1.0,dry:=0.0,splash:=0.7,normal:=Vector3.UP,grow:=0.18)->int:
	var i:=_next;_next=(_next+1)%SPLATS
	_mm.visible_instance_count=maxi(_mm.visible_instance_count,i+1)
	var seed_value:=rng.randf()
	_set_splat(_mm,i,at,size*(0.25 if grow>0.0 else 1.0),normal,rng.randf()*TAU)
	spots[i]=at
	_mm.set_instance_custom_data(i,Color(seed_value,alpha,dry,splash))
	landed+=1
	if grow>0.0 and is_inside_tree():
		var spin:=rng.randf()*TAU
		var t:=create_tween()
		t.tween_method(func(k:float)->void:_set_splat(_mm,i,at,size*lerpf(0.25,1.0,k),normal,spin),0.0,1.0,grow).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	return i

func _set_splat(mm:MultiMesh,i:int,at:Vector3,size:float,normal:Vector3,spin:float)->void:
	var n:=normal.normalized()
	var basis:=Basis.IDENTITY
	if n.distance_to(Vector3.UP)>0.01:
		var x:=n.cross(Vector3.UP if absf(n.y)<0.95 else Vector3.RIGHT).normalized()
		basis=Basis(x,n,x.cross(n).normalized())
	basis=basis*Basis(Vector3.UP,spin)*Basis.from_scale(Vector3(size,1.0,size))
	mm.set_instance_transform(i,Transform3D(basis,at+n*0.012))

## A pool spreading under a body.
func pool(at:Vector3,radius:=0.7,seconds:=2.5)->int:
	var i:=splat(Vector3(at.x,at.y,at.z),radius*2.0,0.95,0.0,0.15,Vector3.UP,0.0)
	_set_splat(_mm,i,at,0.05,Vector3.UP,0.0)
	if is_inside_tree():
		var t:=create_tween()
		t.tween_method(func(k:float)->void:_set_splat(_mm,i,at,lerpf(0.05,radius*2.0,k),Vector3.UP,0.0),0.0,1.0,seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	else:
		_set_splat(_mm,i,at,radius*2.0,Vector3.UP,0.0)
	return i

## The lasting stains on the floor (trophies of the hall): slot index, where,
## how big, how many days old (fading out over fade_days).
func stain(index:int,at:Vector3,size:=1.1,age_days:=0.0,fade_days:=5.0)->void:
	if index<0 or index>=STAINS:return
	var alpha:=clampf(1.0-age_days/fade_days,0.0,1.0)
	stain_alpha[index]=alpha
	_stain_mm.visible_instance_count=STAINS
	if alpha<=0.0:
		_stain_mm.set_instance_transform(index,Transform3D(Basis.from_scale(Vector3(0.001,0.001,0.001)),Vector3(0.0,-50.0,0.0)))
		return
	_set_splat(_stain_mm,index,at,size,Vector3.UP,float(index)*1.7)
	_stain_mm.set_instance_custom_data(index,Color(fmod(float(index)*0.137+0.21,1.0),alpha*0.9,clampf(0.35+age_days/3.0,0.0,1.0),0.4))

func stains_shown()->int:
	var n:=0
	for a in stain_alpha:
		if a>0.0:n+=1
	return n

# --- Flying blood -------------------------------------------------------------------

## A fountain of blood from `at` along `dir` for `seconds`; its drops land
## as splats where they would fall (worked out ballistically, no physics).
func geyser(at:Vector3,dir:=Vector3.UP,seconds:=2.0,power:=1.0)->void:
	var e:=_emitter()
	var pm:=e.process_material as ParticleProcessMaterial
	# a jet, not a spray: a tight column that squirts with the heartbeat
	pm.direction=dir.normalized();pm.spread=7.0
	pm.initial_velocity_min=4.0*power;pm.initial_velocity_max=5.8*power
	e.amount=200;e.explosiveness=0.0;e.lifetime=1.7
	_place(e,at)
	_fire(e,seconds)
	if is_inside_tree():
		var beat:=create_tween()
		for k in maxi(1,int(seconds/0.34)):
			beat.tween_property(e,"amount_ratio",0.25,0.2).set_trans(Tween.TRANS_SINE)
			beat.tween_property(e,"amount_ratio",1.0,0.14).set_trans(Tween.TRANS_SINE)
		beat.tween_property(e,"amount_ratio",1.0,0.01)
	_jet(at,dir.normalized()*4.8*power,seconds)
	_land(at,dir,9.0,4.0*power,5.8*power,clampi(int(11.0*seconds),6,30),seconds)

## The jet itself: a ribbon along the squirt's arc that shoots out of the
## neck, pumps for `seconds`, and lets go.
func _jet(at:Vector3,velocity:Vector3,seconds:float)->void:
	var jet:=_jets[_next_jet];_next_jet=(_next_jet+1)%JETS
	var m:=jet.material_override as ShaderMaterial
	var h:=maxf(at.y,0.0)
	var flight:=(velocity.y+sqrt(velocity.y*velocity.y+2.0*GRAVITY*h))/GRAVITY
	m.set_shader_parameter("velocity",velocity);m.set_shader_parameter("gravity",GRAVITY)
	m.set_shader_parameter("flight",flight)
	m.set_shader_parameter("reach",0.0);m.set_shader_parameter("tail",0.0)
	_place(jet,at)
	jet.visible=true
	if not is_inside_tree():
		m.set_shader_parameter("reach",1.0);return
	var t:=create_tween()
	t.tween_method(func(k:float)->void:m.set_shader_parameter("reach",k),0.0,1.0,flight*0.7).set_ease(Tween.EASE_OUT)
	t.tween_interval(maxf(seconds-flight*0.7,0.1))
	t.tween_method(func(k:float)->void:m.set_shader_parameter("tail",k),0.0,1.0,flight*0.8).set_ease(Tween.EASE_IN)
	t.tween_callback(func()->void:jet.visible=false)

## How many jets are squirting now.
func jets_on()->int:
	var n:=0
	for jet in _jets:if jet.visible:n+=1
	return n

## An arc of blood flung from `from` at the people in `targets` (bodies or
## points): splats land at their feet, stickers on the bodies.
func spray(from:Vector3,targets:Array,power:=1.0)->void:
	if targets.is_empty():return
	var mid:=Vector3.ZERO;var n:=0
	for t in targets:
		var p:=_pos(t)
		mid+=p;n+=1
	mid/=float(maxi(n,1))
	var flat:=Vector3(mid.x-from.x,0.0,mid.z-from.z)
	var dist:=flat.length()
	var dir:=(flat.normalized()+Vector3.UP*0.55).normalized()
	var e:=_emitter()
	var pm:=e.process_material as ParticleProcessMaterial
	pm.direction=dir;pm.spread=24.0
	var v:=sqrt(GRAVITY*maxf(dist,0.8)/0.95)*power
	pm.initial_velocity_min=v*0.75;pm.initial_velocity_max=v*1.1
	e.amount=90;e.explosiveness=0.85;e.lifetime=1.6
	_place(e,from)
	_fire(e,0.25)
	if not is_inside_tree():return
	var flight:=clampf(dist/maxf(v,0.1)*1.1,0.2,0.9)
	var t:=create_tween()
	t.tween_interval(flight)
	for target in targets:
		var at:=_pos(target)
		t.tween_callback(splat.bind(Vector3(at.x+rng.randf_range(-0.3,0.3),0.0,at.z+rng.randf_range(-0.3,0.3)),rng.randf_range(0.25,0.5)))
		if target is Node3D and is_instance_valid(target):t.tween_callback(stain_figure.bind(target,3))
	for k in 6:
		var q:=from.lerp(mid,rng.randf_range(0.4,1.2))
		t.tween_callback(splat.bind(Vector3(q.x+rng.randf_range(-0.5,0.5),0.0,q.z+rng.randf_range(-0.5,0.5)),rng.randf_range(0.12,0.3)))

func _pos(target:Variant)->Vector3:
	if typeof(target)==TYPE_VECTOR3:return target
	if typeof(target)==TYPE_OBJECT and is_instance_valid(target) and target is Node3D:return (target as Node3D).global_position
	return Vector3.ZERO

func _place(e:Node3D,at:Vector3)->void:
	if e.is_inside_tree():e.global_position=at
	else:e.position=at

func _emitter()->GPUParticles3D:
	var e:=_emitters[_next_emitter];_next_emitter=(_next_emitter+1)%EMITTERS
	return e

func _fire(e:GPUParticles3D,seconds:float)->void:
	e.restart()
	e.emitting=true
	if is_inside_tree():
		var t:=create_tween()
		t.tween_interval(maxf(seconds,0.05))
		t.tween_callback(func()->void:e.emitting=false)
	else:
		e.emitting=false

## Where a fountain's drops come down: samples thrown the same way, each
## landing at the time it would, as a splat.
func _land(at:Vector3,dir:Vector3,spread_deg:float,v_min:float,v_max:float,count:int,seconds:float)->void:
	var drops:Array=[]
	var d:=dir.normalized()
	var side:=d.cross(Vector3.FORWARD if absf(d.z)<0.9 else Vector3.RIGHT).normalized()
	for k in count:
		var tilt:=deg_to_rad(rng.randf_range(0.0,spread_deg))
		var v:=d.rotated(side,tilt).rotated(d,rng.randf()*TAU)*rng.randf_range(v_min,v_max)
		var h:=maxf(at.y,0.0)
		var tl:=(v.y+sqrt(v.y*v.y+2.0*GRAVITY*h))/GRAVITY
		var land:=Vector3(at.x+v.x*tl,0.0,at.z+v.z*tl)
		drops.append([rng.randf()*seconds+tl,land])
	drops.sort_custom(func(a:Array,b:Array)->bool:return float(a[0])<float(b[0]))
	if not is_inside_tree():
		for dr in drops:splat(dr[1],rng.randf_range(0.18,0.45),1.0,0.0,0.8,Vector3.UP,0.0)
		return
	var t:=create_tween()
	var last:=0.0
	for dr in drops:
		t.tween_interval(maxf(float(dr[0])-last,0.0));last=float(dr[0])
		t.tween_callback(splat.bind(dr[1],rng.randf_range(0.18,0.45)))

# --- On people ----------------------------------------------------------------------

## Blood on someone: stickers on their chest and face (the rig's chest and
## head bones), reused from a pool; they ride the body as it moves.
func stain_figure(body:Node3D,count:=2)->void:
	if body==null or not is_instance_valid(body):return
	var skels:=body.find_children("*","Skeleton3D",true,false)
	if skels.is_empty():return
	var skel:=skels[0] as Skeleton3D
	for k in count:
		var bone:="chest" if k%2==0 else "head"
		if skel.find_bone(bone)<0:bone="spine"
		if skel.find_bone(bone)<0:continue
		var holder:=_holder(skel,bone)
		var s:=_sticker()
		if s.get_parent()!=null:s.get_parent().remove_child(s)
		holder.add_child(s)
		var front:=0.12 if bone=="chest" else 0.1
		s.position=Vector3(rng.randf_range(-0.08,0.08),rng.randf_range(-0.02,0.12) if bone=="chest" else rng.randf_range(0.04,0.12),front)
		s.rotation=Vector3(0.0,0.0,rng.randf()*TAU)
		var size:=rng.randf_range(0.14,0.24) if bone=="chest" else rng.randf_range(0.09,0.15)
		s.scale=Vector3(size,size,size)
		s.set_instance_shader_parameter("sticker",Color(rng.randf(),1.0,0.0,0.6))
		s.visible=true

func _holder(skel:Skeleton3D,bone:String)->BoneAttachment3D:
	var key:="Blood_"+bone
	var found:=skel.get_node_or_null(key) as BoneAttachment3D
	if found!=null:return found
	var made:=BoneAttachment3D.new();made.name=key;made.bone_name=bone
	skel.add_child(made)
	return made

func _sticker()->MeshInstance3D:
	if _stickers.size()<STICKERS:
		var s:=MeshInstance3D.new();s.name="BloodSticker"
		var quad:=QuadMesh.new();quad.size=Vector2(1.0,1.0);s.mesh=quad
		s.material_override=_splat_mat
		s.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stickers.append(s)
		return s
	var s2:=_stickers[_next_sticker];_next_sticker=(_next_sticker+1)%STICKERS
	return s2

## How many stickers are on people now.
func stickers_on()->int:
	var n:=0
	for s in _stickers:
		if is_instance_valid(s) and s.visible and s.get_parent()!=null:n+=1
	return n

# --- The mist -----------------------------------------------------------------------

## The red mist that paints the hall (the cannon): a red veil over the lens
## that drains away over `seconds`, splats over the floor about `around`.
func mist(lens:Camera3D,seconds:=4.0,around:=Vector3.ZERO,people:Array=[])->void:
	if lens!=null:
		if _mist==null:
			_mist=MeshInstance3D.new();_mist.name="RedMist"
			var quad:=QuadMesh.new();quad.size=Vector2(1.0,1.0);_mist.mesh=quad
			_mist_mat=ShaderMaterial.new();_mist_mat.shader=MIST;_mist_mat.render_priority=95
			_mist.material_override=_mist_mat
			_mist.extra_cull_margin=16384.0
			_mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if _mist.get_parent()!=null:_mist.get_parent().remove_child(_mist)
		lens.add_child(_mist);_mist.position=Vector3(0,0,-0.5);_mist.visible=true
		_mist_mat.set_shader_parameter("seed",rng.randf()*50.0)
		if is_inside_tree():
			var t:=create_tween()
			t.tween_method(func(k:float)->void:_mist_mat.set_shader_parameter("amount",k),0.0,1.0,0.08)
			t.tween_interval(0.5)
			t.tween_method(func(k:float)->void:_mist_mat.set_shader_parameter("amount",k),1.0,0.0,maxf(seconds,0.5)).set_ease(Tween.EASE_IN)
			t.tween_callback(func()->void:_mist.visible=false)
		else:
			_mist_mat.set_shader_parameter("amount",1.0)
	for k in 40:
		var a:=rng.randf()*TAU;var r:=sqrt(rng.randf())*5.0
		splat(around+Vector3(cos(a)*r,0.0,sin(a)*r),rng.randf_range(0.2,0.7),1.0,0.0,0.9,Vector3.UP,0.12)
	for p in people:
		if p is Node3D:stain_figure(p,3)

# --- Clearing -----------------------------------------------------------------------

## The floor and everyone wiped (the lasting stains stay).
func clear()->void:
	for i in SPLATS:
		_mm.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3(0.001,0.001,0.001)),Vector3(0.0,-50.0,0.0)))
	spots.fill(Vector3(0.0,-50.0,0.0))
	_mm.visible_instance_count=0;_next=0
	for s in _stickers:
		if is_instance_valid(s):s.visible=false
	for e in _emitters:e.emitting=false
	for jet in _jets:jet.visible=false
	if _mist!=null:_mist.visible=false
	landed=0
