extends Node
## The court's camera: the lens on the set (scripts/hud/court_set_3d.gd),
## three-quarter from a little above, never a flat lineup. The director
## (court_director.gd) calls shots; nothing here decides anything.
##   wide(subjects, main)  the room: on a wide strip of a stage, the one before
##                         the god large in front with three or four others
##                         at their depths, the frame's edges cropping the
##                         rest; on a taller stage, everyone present
##   two_shot(a, b)        two people, a little closer and lower
##   push_in(fig)          a slow, gentle push onto the speaker
##   reaction(fig)         a cut to someone's face as they take it in
##   shake(strength)       a small jolt for the god's wrath
## A subject is a figure (anything with head_top(), as court_figure_3d.gd
## has), any Node3D, or a point. Shots keep clear of the UI laid over the
## stage (set_insets) and keep the far background softly out of focus.
## It drives one Camera3D (lens): the set's own, or the stage's once the stage
## hands it over (docs/COURT_STAGE_3D.md section 5):
##   CourtStage.camera_rig = preload("res://scripts/hud/court_camera.gd").new()
##   camera_rig.attach(stage, stage.camera, set_root)   # then
##   camera_rig.shot("push_in", {"target": key})        # keys of the stage's cast
## Moves are eased transforms; nothing is allocated per frame, and it stops
## processing when the lens is still.

signal view_changed
signal shot_changed(shot:String)

## A person's height when a subject has no head of its own.
const HEAD:=1.70
const FEET_MARGIN:=0.10
## Name plates stand this far under the feet on the stage (CourtStage.FOOT_ROOM).
const PLATE_ROOM:=40.0

var lens:Camera3D
## The set's own framing: its centre, its usual angle, the yaws it allows.
var centre:=Vector3(0.0,0.9,0.0)
var base_yaw:=22.0
var base_pitch:=-12.0
## The lens's field across the view (degrees), the same whatever the stage's
## shape: a wide strip sees the same width with less height.
var base_fov:=52.0
var yaw_range:=Vector2(-40.0,50.0)
## Fractions of the view kept free of subjects for the UI on top.
var inset_top:=0.0
var inset_bottom:=0.0
var inset_left:=0.0
var inset_right:=0.0
var headroom:=0.22
## The subjects of the last wide shot (what home() returns to), and its main.
var cast:Array=[]
var main:Variant=null
var current_shot:="wide"
## Soft focus on the far background (off on a machine that cannot afford it).
var far_blur:=true

var _from:=Transform3D.IDENTITY
var _to:=Transform3D.IDENTITY
var _fov_from:=52.0
var _fov_to:=52.0
var _focus:=8.0
var _t:=1.0
var _duration:=0.0
var _ease:=0
var _base:=Transform3D.IDENTITY
var _trauma:=0.0
var _shake_t:=0.0
var _noise:=FastNoiseLite.new()
var _moving:=false
var _stage:WeakRef
var _set:WeakRef
var _delegate:Node
var _attributes:CameraAttributesPractical
var _last_shot:="wide"
var _last_args:Dictionary={}

enum {EASE_INOUT,EASE_OUT,EASE_SLOW}

func _init()->void:
	name="CourtCamera"
	_noise.seed=7
	_noise.frequency=1.0
	_noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	set_process(false)

func _ready()->void:
	set_process(_moving or _trauma>0.0)

## Drive this lens from now on (perspective, the field kept across the width).
func use_lens(camera:Camera3D)->void:
	lens=camera
	if lens==null:return
	lens.projection=Camera3D.PROJECTION_PERSPECTIVE
	lens.keep_aspect=Camera3D.KEEP_WIDTH
	lens.fov=base_fov
	lens.near=0.1
	lens.far=400.0
	if _attributes==null:
		_attributes=CameraAttributesPractical.new()
		_attributes.dof_blur_far_enabled=far_blur
		_attributes.dof_blur_far_distance=12.0
		_attributes.dof_blur_far_transition=10.0
		_attributes.dof_blur_amount=0.05
	lens.attributes=_attributes
	_base=lens.transform

## The set's manifest camera entry: {yaw, pitch, fov, centre, yaw_range}.
func configure(info:Dictionary)->void:
	base_yaw=float(info.get("yaw",base_yaw))
	base_pitch=float(info.get("pitch",base_pitch))
	base_fov=float(info.get("fov",base_fov))
	var c:Array=info.get("centre",[centre.x,centre.y,centre.z])
	if c.size()>=3:centre=Vector3(float(c[0]),float(c[1]),float(c[2]))
	var r:Array=info.get("yaw_range",[yaw_range.x,yaw_range.y])
	if r.size()>=2:yaw_range=Vector2(float(r[0]),float(r[1]))
	if lens!=null:lens.fov=base_fov

## The UI laid over the stage, in pixels of the view (the stage's top strip of
## buttons, the name plates under the feet, a plinth at the right).
func set_insets(top_px:float,bottom_px:float,left_px:=0.0,right_px:=0.0)->void:
	var size:=_view_size()
	inset_top=clampf(top_px/size.y,0.0,0.6)
	inset_bottom=clampf(bottom_px/size.y,0.0,0.6)
	inset_left=clampf(left_px/size.x,0.0,0.6)
	inset_right=clampf(right_px/size.x,0.0,0.6)

# --- The stage's seam (docs/COURT_STAGE_3D.md section 5) --------------------------

## The stage hands over its camera and the set it stands in. A rig made on its
## own (CourtStage.camera_rig) hands the work to the set's rig, which lives in
## the set and processes there.
func attach(stage:Node,camera:Camera3D,set_root:Node3D)->void:
	var own:Node=set_root.get("rig") if set_root!=null and is_instance_valid(set_root) else null
	if own!=null and own!=self:
		_delegate=own
		own.call("attach",stage,camera,set_root)
		return
	_delegate=null
	_stage=weakref(stage) if stage!=null else null
	_set=weakref(set_root) if set_root!=null else null
	var old:Camera3D=lens
	use_lens(camera)
	if old!=null and old!=camera and is_instance_valid(old):old.current=false
	if camera!=null:camera.current=true
	if set_root!=null and set_root.get("info") is Dictionary:configure((set_root.get("info") as Dictionary).get("camera",{}))
	_insets_from_stage()
	if stage is Control and not (stage as Control).resized.is_connected(refresh):(stage as Control).resized.connect(refresh)
	shot_named("wide",{},0.0)

func _insets_from_stage()->void:
	var stage:=_stage.get_ref() as Node if _stage!=null else null
	if stage==null:return
	var top:=float(stage.get("top_inset")) if stage.get("top_inset")!=null else 0.0
	var right:=float(stage.get("right_reserve")) if stage.get("right_reserve")!=null else 0.0
	set_insets(top,PLATE_ROOM,0.0,right)

## A shot by name, as the director's beats name them: wide, push_in, reaction,
## two_shot, shake, home. args: target / a / b (keys of the stage's cast, or
## figures, or points), strength, seconds.
func shot(name_in:String,args:Dictionary={})->void:
	if _delegate!=null and is_instance_valid(_delegate):
		_delegate.call("shot",name_in,args);return
	shot_named(name_in,args,-1.0)

func shot_named(name_in:String,args:Dictionary,time:float)->void:
	if name_in!="shake":
		_last_shot=name_in;_last_args=args
	match name_in:
		"push_in":
			var who:Variant=_resolve(args.get("target",args.get("who",null)))
			if who!=null:push_in(who,float(args.get("seconds",5.0)) if time<0.0 else time)
		"reaction":
			var who2:Variant=_resolve(args.get("target",args.get("who",null)))
			if who2!=null:reaction(who2,maxf(time,0.0))
		"two_shot":
			var a:Variant=_resolve(args.get("a",null));var b:Variant=_resolve(args.get("b",null))
			if a!=null and b!=null:two_shot(a,b,0.7 if time<0.0 else time)
		"shake":
			shake(float(args.get("strength",0.35)))
		_:
			var everyone:=_stage_cast()
			var main_body:Variant=_resolve(args.get("main","main"))
			wide(everyone if not everyone.is_empty() else cast,0.9 if time<0.0 else time,main_body)

## The stage changed size: the shot is framed again for the new shape.
func refresh()->void:
	if _delegate!=null and is_instance_valid(_delegate):
		_delegate.call("refresh");return
	_insets_from_stage()
	shot_named(_last_shot,_last_args,0.0)

## A cast key of the stage ("main", "p12") to its body; figures and points pass through.
func _resolve(who:Variant)->Variant:
	if who==null:return null
	if typeof(who)==TYPE_VECTOR3:return who
	if typeof(who)==TYPE_OBJECT:return who if _alive(who) else null
	var stage:=_stage.get_ref() as Node if _stage!=null else null
	if stage==null or not stage.has_method("figure"):return null
	var f:Variant=stage.call("figure",String(who))
	if f==null:return null
	var body:Variant=(f as Object).get("body3d")
	return body if _alive(body) else null

func _stage_cast()->Array:
	var out:Array=[]
	var stage:=_stage.get_ref() as Node if _stage!=null else null
	if stage==null:return out
	for key in stage.get("cast_order") if stage.get("cast_order") is Array else []:
		var f:Variant=stage.call("figure",String(key))
		if f==null or bool((f as Object).get("leaving")):continue
		var body:Variant=(f as Object).get("body3d")
		if _alive(body):out.append(body)
	return out

# --- Shots ------------------------------------------------------------------------

## The room. On a wide strip of a stage: the main (the one before the god;
## else whoever is nearest the god) large and in front, the three or four
## nearest them in at their depths, the edges cropping the rest. On a taller
## stage: everyone present.
func wide(subjects:Array=[],time:=0.9,main_subject:Variant=null)->void:
	if not subjects.is_empty():cast=subjects.duplicate()
	if _alive(main_subject):main=main_subject
	var who:Array=cast if not cast.is_empty() else [centre]
	var t:=clampf((_aspect()-1.9)/1.3,0.0,1.0)
	var pitch:=lerpf(base_pitch,base_pitch*0.55,t)
	var fov:=lerpf(base_fov,base_fov*0.7,t)
	var room:=lerpf(headroom,headroom*0.3,t)
	var lead:Variant=null
	if _alive(main):lead=main
	if lead==null:lead=_nearest_to_god(who)
	var pts:=_room_points(who,lead,t,base_yaw,pitch)
	_go(frame(pts,base_yaw,pitch,fov,room),fov,time,EASE_INOUT,"wide",_focus_for(who,lead))

## Two people: the camera swings a little to favour the line between them and
## comes lower and closer (knees up).
func two_shot(a:Variant,b:Variant,time:=0.7)->void:
	var pa:=_foot_of(a);var pb:=_foot_of(b)
	var across:=pb-pa
	var yaw:=base_yaw
	if across.length()>0.1:
		var side:=Vector2(-across.z,across.x)
		if side.y<0.0:side=-side
		var perpendicular:=rad_to_deg(atan2(side.x,side.y))
		yaw=clampf(lerpf(base_yaw,perpendicular,0.45),yaw_range.x,yaw_range.y)
	var pts:=_points([a,b],false,0.55)
	_go(frame(pts,yaw,base_pitch*0.6,base_fov*0.8,headroom*0.6),base_fov*0.8,time,EASE_INOUT,"two_shot",(_foot_of(a)+_foot_of(b))*0.5)

## A slow, gentle push onto someone speaking: head and shoulders over a few
## seconds, from wherever the camera is now.
func push_in(fig:Variant,seconds:=5.0)->void:
	var yaw:=clampf(lerpf(_current_yaw(),_facing_yaw(fig),0.25),yaw_range.x,yaw_range.y)
	var pts:=_head_points(fig,0.62)
	_go(frame(pts,yaw,base_pitch*0.5,base_fov*0.75,headroom*0.6),base_fov*0.75,seconds,EASE_SLOW,"push_in",_foot_of(fig))

## A cut to someone as they take something in: chest up, turned to see their face.
func reaction(fig:Variant,time:=0.0)->void:
	var yaw:=clampf(lerpf(base_yaw,_facing_yaw(fig),0.55),yaw_range.x,yaw_range.y)
	var pts:=_head_points(fig,0.72)
	_go(frame(pts,yaw,base_pitch*0.45,base_fov*0.72,headroom*0.5),base_fov*0.72,time,EASE_OUT,"reaction",_foot_of(fig))

## Back to the room.
func home(time:=0.9)->void:
	wide([],time)

## Frame these points at once (a still, a test): yaw and pitch in degrees.
func frame_points(points:PackedVector3Array,yaw:=-1000.0,pitch:=-1000.0)->void:
	var y:=base_yaw if yaw<-999.0 else yaw
	var p:=base_pitch if pitch<-999.0 else pitch
	var mid:=Vector3.ZERO
	for q in points:mid+=q
	_go(frame(points,y,p,base_fov,0.0),base_fov,0.0,EASE_INOUT,"still",mid/maxf(1.0,float(points.size())))

## An animal close up (it has no head to frame by).
func frame_animal(animal:Node3D,time:=0.0)->void:
	var at:=animal.global_position
	var pts:=PackedVector3Array([at+Vector3(-0.5,0.0,-0.5),at+Vector3(0.5,0.0,0.5),at+Vector3(0.0,0.75,0.0)])
	_go(frame(pts,clampf(base_yaw,yaw_range.x,yaw_range.y),base_pitch*0.8,base_fov*0.7,0.0),base_fov*0.7,time,EASE_OUT,"animal",at)

## A small jolt (the god's wrath): strength 0..1, it settles in about a second.
func shake(strength:=0.35)->void:
	_trauma=clampf(_trauma+strength,0.0,1.0)
	set_process(true)

func is_moving()->bool:
	return _moving or _trauma>0.0

## Ends any move at once (a test, or the player skipping ahead).
func settle()->void:
	_t=1.0;_trauma=0.0
	_apply(1.0)
	_moving=false
	set_process(false)
	view_changed.emit()

# --- Framing ----------------------------------------------------------------------

## The transform that sees every point from this yaw and pitch through this
## field (across the width), inside the free part of the view, headroom left.
func frame(points:PackedVector3Array,yaw:float,pitch:float,fov_deg:float,head_frac:=0.0)->Transform3D:
	var basis:=Basis.from_euler(Vector3(deg_to_rad(pitch),deg_to_rad(yaw),0.0))
	var right:=basis.x;var up:=basis.y;var back:=basis.z
	if points.is_empty():points=PackedVector3Array([centre])
	var aspect:=_aspect()
	var tan_h:=tan(deg_to_rad(fov_deg)*0.5)
	var tan_v:=tan_h/maxf(aspect,0.1)
	var left_n:=-1.0+2.0*inset_left
	var right_n:=1.0-2.0*inset_right
	var bottom_n:=-1.0+2.0*inset_bottom
	var top_n:=1.0-2.0*inset_top-2.0*head_frac
	if top_n-bottom_n<0.3:top_n=bottom_n+0.3
	var mid:=Vector3.ZERO
	for p in points:mid+=p
	mid/=float(points.size())
	var target:=mid
	var dist:=6.0
	for i in 4:
		dist=0.5
		for p in points:
			var rel:=p-target
			var x:=rel.dot(right);var y:=rel.dot(up);var z:=rel.dot(back)
			var need_x:=0.0
			if x>0.0:need_x=x/(tan_h*right_n) if right_n>0.05 else 99.0
			else:need_x=-x/(tan_h*-left_n) if left_n<-0.05 else 99.0
			var need_y:=0.0
			if y>0.0:need_y=y/(tan_v*top_n) if top_n>0.05 else 99.0
			else:need_y=-y/(tan_v*-bottom_n) if bottom_n<-0.05 else 99.0
			dist=maxf(dist,maxf(need_x,need_y)+z)
		var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
		for p in points:
			var rel:=p-target
			var depth:=maxf(dist-rel.dot(back),0.05)
			var nx:=rel.dot(right)/(depth*tan_h);var ny:=rel.dot(up)/(depth*tan_v)
			lo=Vector2(minf(lo.x,nx),minf(lo.y,ny));hi=Vector2(maxf(hi.x,nx),maxf(hi.y,ny))
		var want:=Vector2((left_n+right_n)*0.5,(bottom_n+top_n)*0.5)
		var shift:=(lo+hi)*0.5-want
		target+=right*shift.x*dist*tan_h+up*shift.y*dist*tan_v
	return Transform3D(basis,target+back*dist)

## A subject that can still be framed: a point, or a node that has not been freed.
static func _alive(subject:Variant)->bool:
	if typeof(subject)==TYPE_VECTOR3:return true
	return typeof(subject)==TYPE_OBJECT and is_instance_valid(subject) and subject is Node3D

func _foot_of(subject:Variant)->Vector3:
	if typeof(subject)==TYPE_VECTOR3:return subject
	if _alive(subject):return (subject as Node3D).global_position
	return centre

func _head_of(subject:Variant)->Vector3:
	if typeof(subject)==TYPE_OBJECT and _alive(subject):
		var node:=subject as Node3D
		if node.has_method("head_top") and node.is_inside_tree():return node.call("head_top")
		return node.global_position+Vector3.UP*HEAD*node.global_transform.basis.get_scale().y
	if typeof(subject)==TYPE_VECTOR3:return (subject as Vector3)+Vector3.UP*HEAD
	return centre+Vector3.UP*HEAD

## The subject nearest the god (the front of the room).
func _nearest_to_god(subjects:Array)->Variant:
	var best:Variant=null;var best_z:=-INF
	for s in subjects:
		var z:=_foot_of(s).z
		if z>best_z:best_z=z;best=s
	return best

## What a room shot must show. t=0 (a tall stage): everyone head to foot.
## t=1 (a wide strip): the main from the knees up, the nearest few by their
## heads and shoulders, nobody else forced in.
func _room_points(subjects:Array,lead:Variant,t:float,yaw:float,pitch:float)->PackedVector3Array:
	var out:=PackedVector3Array()
	var others:Array=[]
	for s in subjects:
		if s!=lead:others.append(s)
	var lead_at:=_foot_of(lead) if lead!=null else centre
	others.sort_custom(func(a:Variant,b:Variant)->bool:return _foot_of(a).distance_to(lead_at)<_foot_of(b).distance_to(lead_at))
	var keep:=int(round(lerpf(float(others.size()),minf(3.0,float(others.size())),t)))
	if lead!=null:
		var foot:=_foot_of(lead);var head:=_head_of(lead)
		out.append(head+Vector3.UP*0.1)
		var low:=foot.lerp(head,lerpf(0.0,0.42,t))-Vector3.UP*FEET_MARGIN*(1.0-t)
		out.append(low)
		out.append(low.lerp(head,0.6)+Vector3(0.32,0.0,0.0))
		out.append(low.lerp(head,0.6)-Vector3(0.32,0.0,0.0))
	for i in keep:
		var s:Variant=others[i]
		var foot2:=_foot_of(s);var head2:=_head_of(s)
		out.append(head2+Vector3.UP*0.08)
		out.append(foot2.lerp(head2,lerpf(0.0,0.86,t))-Vector3.UP*FEET_MARGIN*(1.0-t))
	if out.is_empty():out.append(centre)
	return out

func _points(subjects:Array,whole:bool,from_frac:=0.0)->PackedVector3Array:
	var out:=PackedVector3Array()
	for s in subjects:
		var foot:=_foot_of(s);var head:=_head_of(s)
		var low:=foot.lerp(head,from_frac) if not whole else foot-Vector3.UP*FEET_MARGIN
		out.append(head+Vector3.UP*0.08)
		out.append(low)
		out.append(low.lerp(head,0.6)+Vector3(0.28,0.0,0.0))
		out.append(low.lerp(head,0.6)-Vector3(0.28,0.0,0.0))
	return out

func _head_points(subject:Variant,from_frac:float)->PackedVector3Array:
	var foot:=_foot_of(subject);var head:=_head_of(subject)
	var low:=foot.lerp(head,from_frac)
	return PackedVector3Array([head+Vector3.UP*0.08,low,low+Vector3(0.3,0.0,0.0),low-Vector3(0.3,0.0,0.0)])

## Where a shot is in focus: the back of the room it shows.
func _focus_for(subjects:Array,lead:Variant)->Vector3:
	var at:=_foot_of(lead) if lead!=null else centre
	var furthest:=at
	for s in subjects:
		var p:=_foot_of(s)
		if p.z<furthest.z:furthest=p
	return furthest

## Which way a subject faces (a figure's front is +Z), as a camera yaw that sees its face.
func _facing_yaw(subject:Variant)->float:
	if typeof(subject)==TYPE_OBJECT and _alive(subject):
		var z:=(subject as Node3D).global_transform.basis.z
		if Vector2(z.x,z.z).length()>0.01:return rad_to_deg(atan2(z.x,z.z))
	return base_yaw

func _current_yaw()->float:
	if lens==null:return base_yaw
	var b:=lens.transform.basis.z
	return rad_to_deg(atan2(b.x,b.z))

func _aspect()->float:
	var s:=_view_size()
	return s.x/maxf(s.y,1.0)

func _view_size()->Vector2:
	if lens!=null and lens.is_inside_tree():
		var vp:=lens.get_viewport()
		if vp!=null:
			var r:=vp.get_visible_rect().size
			if r.x>1.0 and r.y>1.0:return r
	return Vector2(1536.0,384.0)

# --- Motion -----------------------------------------------------------------------

func _go(to:Transform3D,to_fov:float,time:float,ease_kind:int,shot_name:String,focus_at:=Vector3.ZERO)->void:
	if lens==null:return
	current_shot=shot_name
	_from=_base if _moving or _trauma>0.0 else lens.transform
	_fov_from=lens.fov
	_to=to;_fov_to=to_fov
	_duration=maxf(time,0.0);_ease=ease_kind;_t=0.0
	# the far background softens past what the shot is about
	_focus=maxf(4.0,(to.origin-focus_at).length()+2.5)
	if _attributes!=null:
		_attributes.dof_blur_far_enabled=far_blur
		_attributes.dof_blur_far_distance=_focus
		_attributes.dof_blur_far_transition=maxf(6.0,_focus*0.8)
	if _duration<=0.0:
		_t=1.0;_apply(1.0);_moving=false
		view_changed.emit()
	else:
		_moving=true
	set_process(_moving or _trauma>0.0)
	shot_changed.emit(shot_name)

func _process(delta:float)->void:
	if lens==null:
		set_process(false);return
	if _moving:
		_t=minf(1.0,_t+delta/maxf(_duration,0.001))
		var k:=_t
		match _ease:
			EASE_INOUT:k=_t*_t*(3.0-2.0*_t)
			EASE_OUT:k=1.0-pow(1.0-_t,3.0)
			EASE_SLOW:k=0.5-0.5*cos(PI*_t)
		_apply(k)
		if _t>=1.0:_moving=false
	else:
		lens.transform=_base
	if _trauma>0.0:
		_shake_t+=delta
		var amount:=_trauma*_trauma
		var pitch_j:=_noise.get_noise_2d(_shake_t*18.0,1.0)*deg_to_rad(1.4)*amount
		var yaw_j:=_noise.get_noise_2d(_shake_t*18.0,7.0)*deg_to_rad(1.1)*amount
		var roll_j:=_noise.get_noise_2d(_shake_t*18.0,13.0)*deg_to_rad(1.6)*amount
		lens.transform=Transform3D(_base.basis*Basis.from_euler(Vector3(pitch_j,yaw_j,roll_j)),_base.origin+_base.basis.y*_noise.get_noise_2d(_shake_t*14.0,21.0)*0.035*amount)
		_trauma=maxf(0.0,_trauma-delta*1.25)
		if _trauma<=0.0:lens.transform=_base
	view_changed.emit()
	if not _moving and _trauma<=0.0:set_process(false)

func _apply(k:float)->void:
	_base=Transform3D(_from.basis.slerp(_to.basis,k),_from.origin.lerp(_to.origin,k))
	lens.fov=lerpf(_fov_from,_fov_to,k)
	lens.transform=_base
