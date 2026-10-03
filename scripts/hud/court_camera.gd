extends Camera3D
## The court's camera: one lens on the set (scripts/hud/court_set_3d.gd),
## three-quarter from a little above, never a flat lineup. The director
## (court_director.gd) calls shots; nothing here decides anything.
##   wide(subjects)        everyone present, the fire between them
##   two_shot(a, b)        two people, a little closer and lower
##   push_in(fig)          a slow, gentle push onto the speaker
##   reaction(fig)         a cut to someone's face as they take it in
##   shake(strength)       a small jolt for the god's wrath
## A subject is a figure (anything with head_top(), as court_figure_3d.gd
## has), any Node3D, or a point. Shots keep clear of the UI laid over the
## stage (set_insets) and of the side of the set that is cut away (the set's
## yaw range). Moves are eased transforms; nothing is allocated per frame,
## and the camera stops processing when it is still.

signal view_changed
signal shot_changed(shot:String)

## A person's height when a subject has no head of its own.
const HEAD:=1.70
const FEET_MARGIN:=0.10

## The set's own framing: its centre, its usual angle, the yaws it allows.
var centre:=Vector3(0.0,0.9,0.0)
var base_yaw:=24.0
var base_pitch:=-13.0
## The lens's field across the view (degrees): kept the same whatever the
## stage's shape, so a wide strip sees the same width, only less height.
var base_fov:=52.0
var yaw_range:=Vector2(-30.0,55.0)
## Fractions of the view kept free of subjects for the UI on top (the
## buttons strip, the name plates, the offered object's plinth) and a little
## headroom above the heads for the speech bubbles.
var inset_top:=0.0
var inset_bottom:=0.0
var inset_left:=0.0
var inset_right:=0.0
var headroom:=0.22
## The subjects of the last wide shot (what home() returns to).
var cast:Array=[]
var shot:="wide"

var _from:=Transform3D.IDENTITY
var _to:=Transform3D.IDENTITY
var _fov_from:=30.0
var _fov_to:=30.0
var _t:=1.0
var _duration:=0.0
var _ease:=0
var _base:=Transform3D.IDENTITY
var _trauma:=0.0
var _shake_t:=0.0
var _noise:=FastNoiseLite.new()
var _moving:=false

enum {EASE_INOUT,EASE_OUT,EASE_SLOW}

func _init()->void:
	name="CourtCamera"
	keep_aspect=Camera3D.KEEP_WIDTH
	fov=base_fov
	near=0.1
	far=400.0
	_noise.seed=7
	_noise.frequency=1.0
	_noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	set_process(false)

func _ready()->void:
	# _process is switched on by itself at ready; only a move or a jolt needs it
	set_process(_moving or _trauma>0.0)

## The set's manifest camera entry: {yaw, pitch, fov, centre, yaw_range}.
func configure(info:Dictionary)->void:
	base_yaw=float(info.get("yaw",base_yaw))
	base_pitch=float(info.get("pitch",base_pitch))
	base_fov=float(info.get("fov",base_fov))
	var c:Array=info.get("centre",[centre.x,centre.y,centre.z])
	if c.size()>=3:centre=Vector3(float(c[0]),float(c[1]),float(c[2]))
	var r:Array=info.get("yaw_range",[yaw_range.x,yaw_range.y])
	if r.size()>=2:yaw_range=Vector2(float(r[0]),float(r[1]))
	fov=base_fov

## The UI laid over the stage, in pixels of the view (the stage's top strip of
## buttons, the name plates under the feet, a plinth at the right).
func set_insets(top_px:float,bottom_px:float,left_px:=0.0,right_px:=0.0)->void:
	var size:=_view_size()
	inset_top=clampf(top_px/size.y,0.0,0.6)
	inset_bottom=clampf(bottom_px/size.y,0.0,0.6)
	inset_left=clampf(left_px/size.x,0.0,0.6)
	inset_right=clampf(right_px/size.x,0.0,0.6)

# --- Shots ------------------------------------------------------------------------

## Everyone present, the fire between them. subjects: figures/nodes/points;
## none: the last cast (or the set's centre).
func wide(subjects:Array=[],time:=0.9)->void:
	if not subjects.is_empty():cast=subjects.duplicate()
	var who:Array=cast if not cast.is_empty() else [centre]
	# a wide stage (the court's strip) is a frieze: lower, closer, less headroom
	var wide_view:=_aspect()>2.4
	var pitch:=base_pitch*(0.9 if wide_view else 1.0)
	var room:=headroom*(0.45 if wide_view else 1.0)
	var pts:=_frieze_points(who,base_yaw,pitch)
	_go(frame(pts,base_yaw,pitch,base_fov,room),base_fov,time,EASE_INOUT,"wide")

## Two people: the camera swings a little to favour the line between them and
## comes lower and closer (knees up).
func two_shot(a:Variant,b:Variant,time:=0.7)->void:
	var pa:=_foot_of(a);var pb:=_foot_of(b)
	var across:=pb-pa
	# look across the pair from the god's side, a little off the perpendicular
	var yaw:=base_yaw
	if across.length()>0.1:
		# the side of the pair the god looks from
		var side:=Vector2(-across.z,across.x)
		if side.y<0.0:side=-side
		var perpendicular:=rad_to_deg(atan2(side.x,side.y))
		yaw=clampf(lerpf(base_yaw,perpendicular,0.45),yaw_range.x,yaw_range.y)
	var pts:=_points([a,b],false,0.55)
	_go(frame(pts,yaw,base_pitch*0.7,base_fov*0.9,headroom*0.8),base_fov*0.9,time,EASE_INOUT,"two_shot")

## A slow, gentle push onto someone speaking: head and shoulders over a few
## seconds, from wherever the camera is now.
func push_in(fig:Variant,seconds:=5.0)->void:
	var yaw:=_current_yaw()
	yaw=clampf(lerpf(yaw,_facing_yaw(fig),0.25),yaw_range.x,yaw_range.y)
	var pts:=_head_points(fig,0.62)
	_go(frame(pts,yaw,base_pitch*0.6,base_fov*0.82,headroom*0.7),base_fov*0.82,seconds,EASE_SLOW,"push_in")

## A cut to someone as they take something in: chest up, turned to see their face.
func reaction(fig:Variant,time:=0.0)->void:
	var yaw:=clampf(lerpf(base_yaw,_facing_yaw(fig),0.55),yaw_range.x,yaw_range.y)
	var pts:=_head_points(fig,0.75)
	_go(frame(pts,yaw,base_pitch*0.5,base_fov*0.8,headroom*0.6),base_fov*0.8,time,EASE_OUT,"reaction")

## Frame these points at once (a still, a test): yaw and pitch in degrees.
func frame_points(points:PackedVector3Array,yaw:=-1000.0,pitch:=-1000.0)->void:
	var y:=base_yaw if yaw<-999.0 else yaw
	var p:=base_pitch if pitch<-999.0 else pitch
	_go(frame(points,y,p,base_fov,0.0),base_fov,0.0,EASE_INOUT,"still")

## An animal close up (it has no head of its own to frame by).
func frame_dog(animal:Node3D,time:=0.0)->void:
	var at:=animal.global_position
	var pts:=PackedVector3Array([at+Vector3(-0.45,0.0,-0.45),at+Vector3(0.45,0.0,0.45),at+Vector3(0.0,0.8,0.0)])
	_go(frame(pts,clampf(base_yaw,yaw_range.x,yaw_range.y),base_pitch*0.7,base_fov*0.8,0.0),base_fov*0.8,time,EASE_OUT,"animal")

## Back to the wide shot of everyone.
func home(time:=0.9)->void:
	wide([],time)

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
## field of view, inside the free part of the view, with headroom left above.
func frame(points:PackedVector3Array,yaw:float,pitch:float,fov_deg:float,head_frac:=0.0)->Transform3D:
	var basis:=Basis.from_euler(Vector3(deg_to_rad(pitch),deg_to_rad(yaw),0.0))
	var right:=basis.x;var up:=basis.y;var back:=basis.z
	if points.is_empty():points=PackedVector3Array([centre])
	var aspect:=_aspect()
	var tan_h:=tan(deg_to_rad(fov_deg)*0.5)
	var tan_v:=tan_h/maxf(aspect,0.1)
	# the free window in normalised device units (-1..1)
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
		# the distance at which every point fits, then centre the points in the window
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
			var depth:=dist-rel.dot(back)
			if depth<0.05:depth=0.05
			var nx:=rel.dot(right)/(depth*tan_h);var ny:=rel.dot(up)/(depth*tan_v)
			lo=Vector2(minf(lo.x,nx),minf(lo.y,ny));hi=Vector2(maxf(hi.x,nx),maxf(hi.y,ny))
		var want:=Vector2((left_n+right_n)*0.5,(bottom_n+top_n)*0.5)
		var have:=(lo+hi)*0.5
		var shift:=have-want
		target+=right*shift.x*dist*tan_h+up*shift.y*dist*tan_v
	return Transform3D(basis,target+back*dist)

## Where something's feet are.
func _foot_of(subject:Variant)->Vector3:
	if subject is Vector3:return subject
	if subject is Node3D and is_instance_valid(subject):return (subject as Node3D).global_position
	return centre

func _head_of(subject:Variant)->Vector3:
	if subject is Node3D and is_instance_valid(subject):
		var node:=subject as Node3D
		if node.has_method("head_top") and node.is_inside_tree():return node.call("head_top")
		return node.global_position+Vector3.UP*HEAD*node.global_transform.basis.get_scale().y
	if subject is Vector3:return (subject as Vector3)+Vector3.UP*HEAD
	return centre+Vector3.UP*HEAD

## The points that must be seen of the subjects: head and feet (whole bodies),
## or only from `from_frac` of the height up (knees, chest).
func _points(subjects:Array,whole:bool,from_frac:=0.0)->PackedVector3Array:
	var out:=PackedVector3Array()
	for s in subjects:
		var foot:=_foot_of(s);var head:=_head_of(s)
		var low:=foot.lerp(head,from_frac) if not whole else foot-Vector3.UP*FEET_MARGIN
		out.append(head+Vector3.UP*0.08)
		out.append(low)
		# a body has width: half a shoulder each side
		out.append(low.lerp(head,0.6)+Vector3(0.28,0.0,0.0))
		out.append(low.lerp(head,0.6)-Vector3(0.28,0.0,0.0))
	return out

## Everyone's head and shoulders, but only the front row's feet: those
## further back are seen over the shoulders of the nearer, as in a crowd.
func _frieze_points(subjects:Array,yaw:float,pitch:float)->PackedVector3Array:
	var back:=Basis.from_euler(Vector3(deg_to_rad(pitch),deg_to_rad(yaw),0.0)).z
	var nearest:=-INF;var furthest:=INF
	for s in subjects:
		var d:=_foot_of(s).dot(back)
		nearest=maxf(nearest,d);furthest=minf(furthest,d)
	var out:=PackedVector3Array()
	for s in subjects:
		var foot:=_foot_of(s);var head:=_head_of(s)
		var front:=(foot.dot(back)-furthest)/maxf(nearest-furthest,0.01)
		out.append(head+Vector3.UP*0.08)
		out.append(head.lerp(foot,0.35)+Vector3(0.3,0.0,0.0))
		out.append(head.lerp(foot,0.35)-Vector3(0.3,0.0,0.0))
		# the front row stands in full; the rest from the knees up at least
		var low:=foot-Vector3.UP*FEET_MARGIN if front>0.55 else foot.lerp(head,clampf(0.55-front,0.0,0.45))
		out.append(low)
	return out

func _head_points(subject:Variant,from_frac:float)->PackedVector3Array:
	var foot:=_foot_of(subject);var head:=_head_of(subject)
	var low:=foot.lerp(head,from_frac)
	return PackedVector3Array([head+Vector3.UP*0.08,low,low+Vector3(0.3,0.0,0.0),low-Vector3(0.3,0.0,0.0)])

## Which way a subject faces, as a camera yaw that would see their face.
func _facing_yaw(subject:Variant)->float:
	if subject is Node3D and is_instance_valid(subject):
		var z:=(subject as Node3D).global_transform.basis.z
		if Vector2(z.x,z.z).length()>0.01:return rad_to_deg(atan2(z.x,z.z))
	return base_yaw

func _current_yaw()->float:
	var b:=transform.basis.z
	return rad_to_deg(atan2(b.x,b.z))

func _aspect()->float:
	var s:=_view_size()
	return s.x/maxf(s.y,1.0)

func _view_size()->Vector2:
	if is_inside_tree():
		var vp:=get_viewport()
		if vp!=null:
			var r:=vp.get_visible_rect().size
			if r.x>1.0 and r.y>1.0:return r
	return Vector2(1536.0,384.0)

# --- Motion -----------------------------------------------------------------------

func _go(to:Transform3D,to_fov:float,time:float,ease_kind:int,shot_name:String)->void:
	shot=shot_name
	_from=_base if _moving or _trauma>0.0 else transform
	_fov_from=fov
	_to=to;_fov_to=to_fov
	_duration=maxf(time,0.0);_ease=ease_kind;_t=0.0
	if _duration<=0.0:
		_t=1.0;_apply(1.0);_moving=false
		view_changed.emit()
	else:
		_moving=true
	set_process(_moving or _trauma>0.0)
	shot_changed.emit(shot_name)

func _process(delta:float)->void:
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
		transform=_base
	if _trauma>0.0:
		_shake_t+=delta
		var amount:=_trauma*_trauma
		var pitch_j:=_noise.get_noise_2d(_shake_t*18.0,1.0)*deg_to_rad(1.4)*amount
		var yaw_j:=_noise.get_noise_2d(_shake_t*18.0,7.0)*deg_to_rad(1.1)*amount
		var roll_j:=_noise.get_noise_2d(_shake_t*18.0,13.0)*deg_to_rad(1.6)*amount
		transform=Transform3D(_base.basis*Basis.from_euler(Vector3(pitch_j,yaw_j,roll_j)),_base.origin+_base.basis.y*_noise.get_noise_2d(_shake_t*14.0,21.0)*0.035*amount)
		_trauma=maxf(0.0,_trauma-delta*1.25)
		if _trauma<=0.0:transform=_base
	view_changed.emit()
	if not _moving and _trauma<=0.0:set_process(false)

func _apply(k:float)->void:
	var to:=_to
	_base=Transform3D(_from.basis.slerp(to.basis,k),_from.origin.lerp(to.origin,k))
	fov=lerpf(_fov_from,_fov_to,k)
	transform=_base
