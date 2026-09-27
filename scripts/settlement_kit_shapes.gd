extends RefCounted
## SETTLEMENT KIT SHAPES (codex/beauty-3): the early buildings, built in code
## as low-poly forms that read from the air in the map's ink
## (settlement_ink.gd paints them: warm light, cool shade, a drawn edge).
##
## Round huts with wattle walls, a dark doorway, a deep conical thatch with a
## bound eave and a smoke hole; thatched timber houses with hipped ends, a
## ridge pole and gablet smoke vents; granaries on stilts with a ladder; open
## work shelters; hide ridge tents and pole tents; branch lean-tos; flat-roofed
## mud-brick houses with beam ends and a roof ladder.
##
## Metres, ground at y = 0, the door toward +Z (the renderers turn +Z to face
## the frontage). Each shape is fitted to the envelope of the kit mesh it
## replaces, so the shared placement solver sees exactly the same footprint.
## Vertex colours only (one surface); meshes are cached.

const STRAW:=Color(0.70,0.58,0.36)
const STRAW_DARK:=Color(0.52,0.41,0.25)
const WATTLE:=Color(0.60,0.50,0.37)
const DAUB:=Color(0.70,0.60,0.45)
const TIMBER:=Color(0.36,0.26,0.17)
const TIMBER_DARK:=Color(0.24,0.17,0.11)
const DOORWAY:=Color(0.10,0.075,0.055)
const HIDE:=Color(0.72,0.60,0.44)
const HIDE_DARK:=Color(0.55,0.44,0.31)
const MUD:=Color(0.68,0.54,0.38)
const MUD_DARK:=Color(0.55,0.42,0.29)
const BARK:=Color(0.40,0.33,0.22)
const LEAF:=Color(0.34,0.36,0.22)

static var cache:Dictionary={}

## A shape for `name` fitted into `envelope` (the replaced mesh's AABB), or
## null when there is no coded shape for it.
static func mesh(name:String,envelope:AABB)->ArrayMesh:
	var key:="%s|%s" % [name,envelope]
	if cache.has(key):return cache[key]
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	match name:
		"round_household":_round_house(s)
		"carried_round":_pole_tent(s)
		"carried_ridge":_ridge_tent(s)
		"rooted_lean_to":_lean_to(s)
		"raised_store":_granary(s)
		"covered_workshop":_work_shelter(s)
		"earthen_household":_mud_house(s)
		"house_narrow","house_compact","house_medium","house_wide","house_small":_thatched_house(s,name)
		_:return null
	var built:=s.commit()
	var fitted:=_fit(built,envelope)
	cache[key]=fitted
	return fitted

## The furniture of daily life, in metres (door or front toward +Z):
## woodpile, drying_rack, hide_frame, hearth_ring, bench, pots, quern, well,
## water_jars, midden, kiln, loom, pen_wattle, pen_stone, frame,
## timber_stack. Cached; null for an unknown name.
static func prop(name:String)->ArrayMesh:
	if cache.has("prop|"+name):return cache["prop|"+name]
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	match name:
		"woodpile":
			for layer in 3:
				for k in 4-layer:
					var x:=(float(k)-float(3-layer)*0.5)*0.34
					_beam(s,Vector3(x,0.16+layer*0.28,-0.75),Vector3(x,0.16+layer*0.28,0.75),0.15,BARK.darkened(0.1*float((k+layer)%2)))
			_box(s,Vector3(0,0.02,0),Vector3(1.5,0.04,1.7),TIMBER_DARK)
		"drying_rack":
			for x in [-1.1,1.1]:
				_beam(s,Vector3(x,0,-0.5),Vector3(x,1.6,0),0.05,TIMBER)
				_beam(s,Vector3(x,0,0.5),Vector3(x,1.6,0),0.05,TIMBER)
			_beam(s,Vector3(-1.25,1.55,0),Vector3(1.25,1.55,0),0.05,TIMBER_DARK)
			for k in 6:
				var x:=-0.9+float(k)*0.36
				var tone:=Color(0.55,0.28,0.18) if k%3==0 else Color(0.62,0.48,0.32)
				_box(s,Vector3(x,1.15,0.02),Vector3(0.22,0.75,0.03),tone)
		"hide_frame":
			for x in [-0.8,0.8]:_beam(s,Vector3(x,0,0),Vector3(x,1.7,0),0.05,TIMBER)
			_beam(s,Vector3(-0.9,1.6,0),Vector3(0.9,1.6,0),0.05,TIMBER)
			_beam(s,Vector3(-0.9,0.25,0),Vector3(0.9,0.25,0),0.05,TIMBER)
			_box(s,Vector3(0,0.93,0.03),Vector3(1.35,1.15,0.03),HIDE)
		"hearth_ring":
			for k in 11:
				var a:=TAU*float(k)/11.0
				_box(s,Vector3(sin(a)*0.85,0.11,cos(a)*0.85),Vector3(0.32,0.22,0.28),Color(0.46,0.45,0.41).darkened(0.08*float(k%3)))
			_frustum(s,Vector3(0,0,0),0.62,0.45,0.10,10,Color(0.20,0.16,0.13),0.0)
			_frustum(s,Vector3(0,0.10,0),0.34,0.12,0.16,8,Color(0.95,0.48,0.14),0.0)
			for k in 3:
				var a:=TAU*float(k)/3.0+0.5
				_beam(s,Vector3(sin(a)*0.1,0.14,cos(a)*0.1),Vector3(sin(a)*0.65,0.08,cos(a)*0.65),0.07,TIMBER_DARK)
		"bench":
			_beam(s,Vector3(-1.1,0.2,0),Vector3(1.1,0.2,0),0.2,BARK)
		"pots":
			var at:=[Vector3(0,0,0),Vector3(0.42,0,0.1),Vector3(0.12,0,0.42),Vector3(-0.35,0,0.25)]
			for k in at.size():
				var r:=0.20-0.03*float(k%2)
				var tone:=Color(0.62,0.40,0.26) if k%2==0 else Color(0.52,0.34,0.22)
				_frustum(s,at[k],r*0.7,r,r*1.1,8,tone,0.0)
				_frustum(s,at[k]+Vector3(0,r*1.1,0),r,r*0.55,r*0.7,8,tone.lightened(0.05),0.0)
		"quern":
			_frustum(s,Vector3.ZERO,0.42,0.38,0.14,8,Color(0.50,0.48,0.43),0.0)
			_box(s,Vector3(0.05,0.2,0),Vector3(0.36,0.1,0.18),Color(0.44,0.42,0.38))
			_frustum(s,Vector3(0.6,0,0.2),0.26,0.22,0.36,8,Color(0.46,0.36,0.22),0.0)
		"well":
			_frustum(s,Vector3.ZERO,0.85,0.80,0.62,12,Color(0.52,0.50,0.45),0.1)
			_frustum(s,Vector3(0,0.62,0),0.58,0.58,0.01,12,Color(0.12,0.16,0.18),0.0)
			for x in [-0.95,0.95]:_beam(s,Vector3(x,0,0),Vector3(x,1.7,0),0.07,TIMBER)
			_beam(s,Vector3(-1.05,1.62,0),Vector3(1.05,1.62,0),0.07,TIMBER_DARK)
			_frustum(s,Vector3(0.3,1.0,0),0.16,0.18,0.28,8,TIMBER,0.0)
		"water_jars":
			for k in 3:
				var at2:=Vector3(float(k)*0.55-0.55,0,float(k%2)*0.3)
				_frustum(s,at2,0.20,0.30,0.35,8,Color(0.60,0.42,0.28),0.0)
				_frustum(s,at2+Vector3(0,0.35,0),0.30,0.14,0.30,8,Color(0.64,0.46,0.30),0.0)
		"midden":
			_cone_roof(s,Vector3.ZERO,1.6,0.3,0.55,10,Color(0.24,0.20,0.15),0.12)
			for k in 5:
				var a:=float(k)*1.3
				_box(s,Vector3(sin(a)*0.8,0.35,cos(a)*0.6),Vector3(0.25,0.08,0.12),Color(0.70,0.66,0.56))
		"kiln":
			_cone_roof(s,Vector3.ZERO,0.85,0.25,1.15,10,Color(0.62,0.44,0.30),0.08)
			_frustum(s,Vector3(0,1.15,0),0.25,0.18,0.12,8,Color(0.30,0.22,0.16),0.0)
			_box(s,Vector3(0,0.25,0.78),Vector3(0.42,0.42,0.12),DOORWAY)
			for k in 3:_beam(s,Vector3(-0.9+float(k)*0.2,0.08,1.1),Vector3(-0.2+float(k)*0.2,0.08,1.5),0.07,BARK)
		"loom":
			for x in [-0.8,0.8]:_beam(s,Vector3(x,0,0),Vector3(x,1.8,-0.15),0.05,TIMBER)
			_beam(s,Vector3(-0.9,1.72,-0.13),Vector3(0.9,1.72,-0.13),0.05,TIMBER_DARK)
			_box(s,Vector3(0,1.05,-0.06),Vector3(1.4,1.2,0.02),Color(0.80,0.74,0.60))
			for k in 6:_frustum(s,Vector3(-0.6+float(k)*0.24,0.3,0.02),0.06,0.05,0.12,6,Color(0.50,0.45,0.38),0.0)
		"pen_wattle","pen_stone":
			var stone:=name=="pen_stone"
			var n:=16
			for k in n:
				if k==0:continue # the gate gap faces +Z
				var a0:=TAU*(float(k)-0.5)/float(n);var a1:=TAU*(float(k)+0.5)/float(n)
				var p0:=Vector3(sin(a0),0,cos(a0))*4.5;var p1:=Vector3(sin(a1),0,cos(a1))*4.5
				if stone:
					_box_between(s,p0,p1,0.55,0.62,Color(0.54,0.52,0.47).darkened(0.07*float(k%3)))
				else:
					_beam(s,p0,p0+Vector3(0,1.05,0),0.05,TIMBER_DARK)
					for y in [0.35,0.65,0.95]:
						_beam(s,p0+Vector3(0,y,0),p1+Vector3(0,y,0),0.06,BARK.lerp(STRAW_DARK,0.3))
			# A trough and a heap of fodder.
			_box(s,Vector3(-1.8,0.18,-1.5),Vector3(1.4,0.36,0.5),TIMBER)
			_cone_roof(s,Vector3(2.0,0,-1.2),0.8,0.1,0.7,8,STRAW,0.05)
		"frame":
			# A house going up: posts, a ring beam and the first rafters.
			for x in [-1,1]:
				for z in [-1,1]:
					_beam(s,Vector3(x*1.5,0,z*1.6),Vector3(x*1.5,1.7,z*1.6),0.08,TIMBER)
			for z in [-1,1]:_beam(s,Vector3(-1.6,1.7,z*1.6),Vector3(1.6,1.7,z*1.6),0.07,TIMBER)
			for x in [-1,1]:_beam(s,Vector3(x*1.5,1.7,-1.7),Vector3(x*1.5,1.7,1.7),0.07,TIMBER)
			for z in [-1.3,0.0,1.3]:
				_beam(s,Vector3(-1.6,1.65,z),Vector3(0,3.1,z),0.05,TIMBER_DARK)
				_beam(s,Vector3(1.6,1.65,z),Vector3(0,3.1,z),0.05,TIMBER_DARK)
			_box(s,Vector3(-1.5,0.45,0),Vector3(0.06,0.9,3.2),WATTLE)
		"timber_stack":
			for layer in 2:
				for k in 5:
					_beam(s,Vector3(-1.6,0.1+layer*0.2,(float(k)-2.0)*0.2),Vector3(1.6,0.1+layer*0.2,(float(k)-2.0)*0.2+0.05),0.09,TIMBER.lightened(0.05*float(k%2)))
			_cone_roof(s,Vector3(0,0,1.4),0.7,0.05,0.5,8,STRAW,0.05)
		_:return null
	var built:=s.commit()
	cache["prop|"+name]=built
	return built

## A block of dry-stone wall from p0 to p1 (height h, thickness t).
static func _box_between(s:SurfaceTool,p0:Vector3,p1:Vector3,h:float,t:float,color:Color)->void:
	var along:=(p1-p0);along.y=0.0
	var side:=along.cross(Vector3.UP).normalized()*t*0.5
	var a:=p0-side;var b:=p1-side;var c:=p1+side;var d:=p0+side
	var up:=Vector3(0,h,0)
	_quad(s,a+up,b+up,c+up,d+up,color.lightened(0.05),Vector3.UP)
	_quad(s,a,b,b+up,a+up,color,-side)
	_quad(s,d,c,c+up,d+up,color,side)

# --- Buildings ---------------------------------------------------------------

static func _round_house(s:SurfaceTool)->void:
	var sides:=18
	# Wattle wall: stakes and daub, alternating a little in tone.
	_ring_wall(s,1.50,0.0,1.28,sides,WATTLE,0.07)
	# Doorway with a timber frame, toward +Z.
	_box(s,Vector3(0,0.56,1.515),Vector3(0.78,1.12,0.05),DOORWAY)
	_box(s,Vector3(-0.44,0.6,1.52),Vector3(0.1,1.2,0.08),TIMBER)
	_box(s,Vector3(0.44,0.6,1.52),Vector3(0.1,1.2,0.08),TIMBER)
	_box(s,Vector3(0,1.18,1.53),Vector3(1.0,0.1,0.1),TIMBER)
	# Deep thatch: a bound eave band, then the cone to a smoke hole.
	_frustum(s,Vector3(0,1.08,0),1.95,1.90,0.20,sides,STRAW_DARK,0.05)
	_cone_roof(s,Vector3(0,1.28,0),1.90,0.20,1.62,sides,STRAW,0.06)
	# Smoke hole collar and the binding at the top.
	_frustum(s,Vector3(0,2.88,0),0.22,0.10,0.14,8,TIMBER_DARK,0.0)
	# Two thatch courses show as darker rings.
	_frustum(s,Vector3(0,1.82,0),1.30,1.26,0.05,sides,STRAW_DARK,0.0)
	_frustum(s,Vector3(0,2.32,0),0.75,0.71,0.05,sides,STRAW_DARK,0.0)

static func _thatched_house(s:SurfaceTool,variant:String)->void:
	# A timber-framed, wattle-walled house under a steep hipped thatch.
	var length:=7.0
	var width:=4.0
	match variant:
		"house_narrow":length=7.2;width=3.6
		"house_compact":length=6.0;width=4.2
		"house_medium":length=5.6;width=4.8
		"house_wide":length=5.0;width=5.4
		"house_small":length=4.2;width=3.6
	var wall_h:=1.7
	# Walls (long axis along Z), a darker sill course and corner posts.
	_box(s,Vector3(0,wall_h*0.5,0),Vector3(width-0.5,wall_h,length-0.5),WATTLE)
	_box(s,Vector3(0,0.12,0),Vector3(width-0.42,0.24,length-0.42),TIMBER)
	for x in [-1,1]:
		for z in [-1,1]:
			_box(s,Vector3(x*(width*0.5-0.25),wall_h*0.5,z*(length*0.5-0.25)),Vector3(0.16,wall_h,0.16),TIMBER)
	# Door on the gable toward +Z, a second on the long side.
	_box(s,Vector3(0,0.6,length*0.5-0.23),Vector3(0.9,1.2,0.06),DOORWAY)
	_box(s,Vector3(width*0.5-0.23,0.6,0.4),Vector3(0.06,1.15,0.8),DOORWAY)
	# Hipped thatch with deep eaves.
	var eave:=Vector2(width*0.5+0.35,length*0.5+0.35)
	var ridge_half:=maxf(length*0.5-width*0.45,0.4)
	var top:=wall_h+width*0.62+0.6
	_hipped_roof(s,wall_h-0.05,top,eave,ridge_half,STRAW)
	# Eave band (the cut thatch edge) and the ridge.
	_box(s,Vector3(0,wall_h-0.12,0),Vector3(eave.x*2.0,0.16,eave.y*2.0),STRAW_DARK)
	_box(s,Vector3(0,top+0.06,0),Vector3(0.22,0.16,ridge_half*2.0+0.5),TIMBER_DARK)
	# Gablet smoke vents at the ridge ends.
	for z in [-1,1]:
		_box(s,Vector3(0,top-0.28,z*(ridge_half+0.1)),Vector3(0.5,0.36,0.12),DOORWAY)

static func _granary(s:SurfaceTool)->void:
	# A store on stilts, out of reach of damp and vermin.
	for x in [-1,1]:
		for z in [-1,1]:
			_box(s,Vector3(x*1.05,0.45,z*1.15),Vector3(0.16,0.9,0.16),TIMBER_DARK)
			# Rat stones: flat caps on the stilts.
			_frustum(s,Vector3(x*1.05,0.86,z*1.15),0.26,0.22,0.08,8,Color(0.55,0.52,0.46),0.0)
	_box(s,Vector3(0,0.98,0),Vector3(2.6,0.14,2.8),TIMBER)
	_box(s,Vector3(0,1.55,0),Vector3(2.3,1.0,2.5),WATTLE)
	_box(s,Vector3(0,1.5,1.26),Vector3(0.6,0.7,0.05),DOORWAY)
	# Ladder up to the door.
	for x in [-0.25,0.25]:
		_beam(s,Vector3(x,0.0,2.0),Vector3(x,1.05,1.36),0.06,TIMBER)
	for k in 4:
		var t:=(float(k)+0.6)/4.6
		_box(s,Vector3(0,t*1.05,lerpf(2.0,1.36,t)),Vector3(0.56,0.05,0.07),TIMBER)
	_hipped_roof(s,2.0,3.12,Vector2(1.55,1.65),0.35,STRAW)
	_box(s,Vector3(0,1.96,0),Vector3(3.1,0.12,3.3),STRAW_DARK)

static func _work_shelter(s:SurfaceTool)->void:
	# Posts under a thatched roof, open on every side, a work log beneath.
	for x in [-1,1]:
		for z in [-1,0,1]:
			_box(s,Vector3(x*1.25,0.85,z*1.25),Vector3(0.13,1.7,0.13),TIMBER)
	_gable_roof(s,1.65,2.5,Vector2(1.55,1.70),STRAW)
	_box(s,Vector3(0,1.62,0),Vector3(3.1,0.1,3.4),STRAW_DARK)
	_beam(s,Vector3(-0.8,0.2,0.3),Vector3(0.7,0.2,-0.2),0.2,BARK)
	_box(s,Vector3(0.5,0.18,0.9),Vector3(0.5,0.36,0.5),Color(0.50,0.48,0.42))
	_box(s,Vector3(-0.6,0.12,-0.8),Vector3(0.8,0.24,0.5),TIMBER)

static func _ridge_tent(s:SurfaceTool)->void:
	# Hides over a ridge pole: two slopes, the door flap at the +Z end.
	var half_len:=1.35
	var half_w:=1.2
	var h:=1.55
	for side in [-1,1]:
		var a:=Vector3(side*half_w,0,-half_len);var b:=Vector3(side*half_w,0,half_len)
		var c:=Vector3(0,h,half_len);var d:=Vector3(0,h,-half_len)
		_quad(s,a,b,c,d,HIDE if side<0 else HIDE_DARK,Vector3(side,1,0))
		# Seams between the hides.
		for k in [-0.45,0.45]:
			_quad(s,Vector3(side*half_w,0.0,k-0.03)+Vector3(side*0.01,0,0),Vector3(side*half_w,0.0,k+0.03)+Vector3(side*0.01,0,0),Vector3(side*0.01,h+0.005,k+0.03),Vector3(side*0.01,h+0.005,k-0.03),HIDE_DARK.darkened(0.25),Vector3(side,1,0))
	# The back closed, the front a dark opening.
	_tri(s,Vector3(-half_w,0,-half_len),Vector3(0,h,-half_len),Vector3(half_w,0,-half_len),HIDE_DARK,Vector3.FORWARD)
	_tri(s,Vector3(-half_w*0.7,0,half_len+0.01),Vector3(half_w*0.7,0,half_len+0.01),Vector3(0,h*0.72,half_len+0.01),DOORWAY,Vector3.BACK)
	_beam(s,Vector3(0,h+0.05,-half_len-0.25),Vector3(0,h+0.05,half_len+0.25),0.05,TIMBER_DARK)

static func _pole_tent(s:SurfaceTool)->void:
	# Hides round a cone of poles, the pole tips crossing above.
	var sides:=12
	_cone_roof(s,Vector3.ZERO,1.55,0.0,2.45,sides,HIDE,0.07)
	_box(s,Vector3(0,0.5,1.33),Vector3(0.62,0.95,0.30),DOORWAY)
	for k in 6:
		var a:=TAU*float(k)/6.0+0.3
		_beam(s,Vector3(cos(a)*0.55,1.75,sin(a)*0.55),Vector3(-cos(a)*0.28,3.1,-sin(a)*0.28),0.04,TIMBER_DARK)
	# A painted band round the hides.
	_frustum(s,Vector3(0,0.55,0),1.22,1.16,0.12,sides,HIDE_DARK,0.0)

static func _lean_to(s:SurfaceTool)->void:
	# Branches and bark laid on a pole frame, open toward +Z.
	for x in [-1.3,0.0,1.3]:
		_beam(s,Vector3(x,0,1.2),Vector3(x,1.9,1.2),0.07,TIMBER)
	_beam(s,Vector3(-1.5,1.9,1.2),Vector3(1.5,1.9,1.2),0.07,TIMBER)
	var a:=Vector3(-1.5,0.05,-1.4);var b:=Vector3(1.5,0.05,-1.4)
	var c:=Vector3(1.5,1.98,1.3);var d:=Vector3(-1.5,1.98,1.3)
	_quad(s,a,b,c,d,BARK,Vector3(0,1,-0.5))
	# Leafy boughs across the roof.
	for k in 4:
		var t:=(float(k)+0.5)/4.0
		var p:=a.lerp(d,t)
		_beam(s,p+Vector3(0,0.06,0),p+Vector3(3.0,0.06,0),0.09,LEAF.lerp(BARK,float(k%2)*0.4))
	_tri(s,Vector3(-1.5,0.05,-1.4),Vector3(-1.5,1.98,1.3),Vector3(-1.5,0.05,1.3),BARK.darkened(0.15),Vector3.LEFT)
	# Bedding and a fire's ash inside.
	_box(s,Vector3(0,0.06,0),Vector3(2.2,0.12,1.4),HIDE_DARK)

static func _mud_house(s:SurfaceTool)->void:
	# Sun-dried brick under plaster, a flat roof of beams and packed earth.
	var w:=2.9;var d:=3.2;var h:=2.15
	_box(s,Vector3(0,h*0.5,0),Vector3(w,h,d),MUD)
	_box(s,Vector3(0,0.1,0),Vector3(w+0.1,0.2,d+0.1),MUD_DARK)
	# Roof and a low parapet.
	_box(s,Vector3(0,h+0.05,0),Vector3(w+0.08,0.1,d+0.08),MUD_DARK)
	for side in [-1,1]:
		_box(s,Vector3(side*(w*0.5-0.05),h+0.16,0),Vector3(0.12,0.22,d),MUD)
		_box(s,Vector3(0,h+0.16,side*(d*0.5-0.05)),Vector3(w,0.22,0.12),MUD)
	# Beam ends through the wall below the roof.
	for k in 5:
		var z:=lerpf(-d*0.4,d*0.4,float(k)/4.0)
		_box(s,Vector3(w*0.5+0.12,h-0.18,z),Vector3(0.3,0.12,0.12),TIMBER)
		_box(s,Vector3(-w*0.5-0.12,h-0.18,z),Vector3(0.3,0.12,0.12),TIMBER)
	_box(s,Vector3(0,0.62,d*0.5+0.01),Vector3(0.8,1.24,0.05),DOORWAY)
	_box(s,Vector3(0.85,1.35,d*0.5+0.01),Vector3(0.35,0.3,0.04),DOORWAY)
	# A roof ladder and a hatch.
	_box(s,Vector3(-0.6,h+0.12,-0.6),Vector3(0.6,0.06,0.6),DOORWAY)
	for x in [-0.95,-0.65]:
		_beam(s,Vector3(x-0.6,0,d*0.5+0.55),Vector3(x-0.6,h+0.5,d*0.5+0.05),0.045,TIMBER)

# --- Primitives (flat-shaded, vertex-coloured) --------------------------------

## One flat triangle facing `out` (default: away from the building's
## middle), wound clockwise as seen from that side (Godot's front face).
static func _tri(s:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,color:Color,out:=Vector3.ZERO)->void:
	var n:=(b-a).cross(c-a)
	if n.length_squared()<1e-12:return
	n=n.normalized()
	var hint:=out if out!=Vector3.ZERO else (a+b+c)/3.0-Vector3(0,1.0,0)
	if n.dot(hint)<0.0:n=-n
	if (b-a).cross(c-a).dot(n)>0.0:
		var t:=b;b=c;c=t
	s.set_color(color);s.set_normal(n)
	s.add_vertex(a);s.add_vertex(b);s.add_vertex(c)

static func _quad(s:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3,color:Color,out:=Vector3.ZERO)->void:
	var hint:=out if out!=Vector3.ZERO else (a+b+c+d)*0.25-Vector3(0,1.0,0)
	_tri(s,a,b,c,color,hint);_tri(s,a,c,d,color,hint)

static func _box(s:SurfaceTool,center:Vector3,size:Vector3,color:Color)->void:
	var h:=size*0.5
	var p:=[center+Vector3(-h.x,-h.y,-h.z),center+Vector3(h.x,-h.y,-h.z),center+Vector3(h.x,-h.y,h.z),center+Vector3(-h.x,-h.y,h.z),
		center+Vector3(-h.x,h.y,-h.z),center+Vector3(h.x,h.y,-h.z),center+Vector3(h.x,h.y,h.z),center+Vector3(-h.x,h.y,h.z)]
	_quad(s,p[4],p[7],p[6],p[5],color.lightened(0.04),Vector3.UP)
	_quad(s,p[3],p[2],p[6],p[7],color,Vector3.BACK)
	_quad(s,p[1],p[0],p[4],p[5],color.darkened(0.06),Vector3.FORWARD)
	_quad(s,p[0],p[3],p[7],p[4],color.darkened(0.03),Vector3.LEFT)
	_quad(s,p[2],p[1],p[5],p[6],color.darkened(0.03),Vector3.RIGHT)

## A slim round-ish beam between two points (a four-sided prism).
static func _beam(s:SurfaceTool,a:Vector3,b:Vector3,radius:float,color:Color)->void:
	var axis:=b-a
	if axis.length()<0.001:return
	var u:=axis.cross(Vector3.UP if absf(axis.normalized().y)<0.9 else Vector3.RIGHT).normalized()*radius
	var v:=axis.cross(u).normalized()*radius
	var ring:=[u,v,-u,-v]
	for k in 4:
		var p0:Vector3=ring[k];var p1:Vector3=ring[(k+1)%4]
		_quad(s,a+p0,a+p1,b+p1,b+p0,color.darkened(0.05*float(k%2)),p0+p1)

## A ring of wall between y0 and y1, its segments alternating in tone.
static func _ring_wall(s:SurfaceTool,radius:float,y0:float,y1:float,sides:int,color:Color,variation:float)->void:
	for k in sides:
		var a0:=TAU*float(k)/float(sides);var a1:=TAU*float(k+1)/float(sides)
		var p0:=Vector3(sin(a0)*radius,0,cos(a0)*radius);var p1:=Vector3(sin(a1)*radius,0,cos(a1)*radius)
		var tone:=color.darkened(variation*float((k*7)%3)*0.5)
		_quad(s,p1+Vector3(0,y0,0),p0+Vector3(0,y0,0),p0+Vector3(0,y1,0),p1+Vector3(0,y1,0),tone,p0+p1)

static func _frustum(s:SurfaceTool,base:Vector3,r0:float,r1:float,height:float,sides:int,color:Color,variation:float)->void:
	for k in sides:
		var a0:=TAU*float(k)/float(sides);var a1:=TAU*float(k+1)/float(sides)
		var tone:=color.darkened(variation*float((k*5)%3)*0.5)
		var b0:=base+Vector3(sin(a0)*r0,0,cos(a0)*r0);var b1:=base+Vector3(sin(a1)*r0,0,cos(a1)*r0)
		var t0:=base+Vector3(sin(a0)*r1,height,cos(a0)*r1);var t1:=base+Vector3(sin(a1)*r1,height,cos(a1)*r1)
		_quad(s,b1,b0,t0,t1,tone,(b0+b1-base*2.0)*Vector3(1,0,1))
	# Top cap.
	if r1>0.001:
		for k in sides:
			var a0:=TAU*float(k)/float(sides);var a1:=TAU*float(k+1)/float(sides)
			_tri(s,base+Vector3(0,height,0),base+Vector3(sin(a1)*r1,height,cos(a1)*r1),base+Vector3(sin(a0)*r1,height,cos(a0)*r1),color.darkened(0.1),Vector3.UP)

## A conical roof from `r0` at the base (eave) to `r1` at `height`, the thatch
## slightly bellied and uneven so it reads as laid straw.
static func _cone_roof(s:SurfaceTool,base:Vector3,r0:float,r1:float,height:float,sides:int,color:Color,variation:float)->void:
	var bands:=3
	for band in bands:
		var t0:=float(band)/float(bands);var t1:=float(band+1)/float(bands)
		var belly0:=sin(t0*PI)*0.10;var belly1:=sin(t1*PI)*0.10
		var ra:=lerpf(r0,r1,t0)+belly0;var rb:=lerpf(r0,r1,t1)+belly1
		for k in sides:
			var a0:=TAU*float(k)/float(sides);var a1:=TAU*float(k+1)/float(sides)
			var j0:=1.0+0.03*sin(float(k)*2.7);var j1:=1.0+0.03*sin(float(k+1)*2.7)
			var tone:=color.darkened(variation*float((k*5+band)%3)*0.5)
			var b0:=base+Vector3(sin(a0)*ra*j0,height*t0,cos(a0)*ra*j0);var b1:=base+Vector3(sin(a1)*ra*j1,height*t0,cos(a1)*ra*j1)
			var c0:=base+Vector3(sin(a0)*rb*j0,height*t1,cos(a0)*rb*j0);var c1:=base+Vector3(sin(a1)*rb*j1,height*t1,cos(a1)*rb*j1)
			_quad(s,b1,b0,c0,c1,tone,(b0+b1-base*2.0)*Vector3(1,0,1)+Vector3(0,0.3,0))

## A hipped roof: eaves at `y0` over half-extents `eave`, a ridge of half
## length `ridge_half` along Z at `y1`.
static func _hipped_roof(s:SurfaceTool,y0:float,y1:float,eave:Vector2,ridge_half:float,color:Color)->void:
	var e0:=Vector3(-eave.x,y0,-eave.y);var e1:=Vector3(eave.x,y0,-eave.y)
	var e2:=Vector3(eave.x,y0,eave.y);var e3:=Vector3(-eave.x,y0,eave.y)
	var r0:=Vector3(0,y1,-ridge_half);var r1:=Vector3(0,y1,ridge_half)
	_quad(s,e3,e0,r0,r1,color.darkened(0.03),Vector3(-1,1,0))
	_quad(s,e1,e2,r1,r0,color,Vector3(1,1,0))
	_tri(s,e2,e3,r1,color.lightened(0.03),Vector3(0,1,1))
	_tri(s,e0,e1,r0,color.darkened(0.05),Vector3(0,1,-1))
	# The underside of the eaves, dark.
	_quad(s,e0,e3,e2,e1,DOORWAY.lerp(color,0.3),Vector3.DOWN)
	# Thatch courses: darker lines along each long slope.
	for t in [0.35,0.68]:
		var a:=e3.lerp(r1,t);var b:=e0.lerp(r0,t)
		_quad(s,b+Vector3(-0.02,0.02,0),a+Vector3(-0.02,0.02,0),a+Vector3(0.0,0.07,0),b+Vector3(0.0,0.07,0),color.darkened(0.22),Vector3(-1,1,0))
		var c:=e1.lerp(r0,t);var d:=e2.lerp(r1,t)
		_quad(s,c+Vector3(0.02,0.02,0),d+Vector3(0.02,0.02,0),d+Vector3(0.0,0.07,0),c+Vector3(0.0,0.07,0),color.darkened(0.22),Vector3(1,1,0))

static func _gable_roof(s:SurfaceTool,y0:float,y1:float,eave:Vector2,color:Color)->void:
	var e0:=Vector3(-eave.x,y0,-eave.y);var e1:=Vector3(eave.x,y0,-eave.y)
	var e2:=Vector3(eave.x,y0,eave.y);var e3:=Vector3(-eave.x,y0,eave.y)
	var r0:=Vector3(0,y1,-eave.y);var r1:=Vector3(0,y1,eave.y)
	_quad(s,e3,e0,r0,r1,color.darkened(0.03),Vector3(-1,1,0))
	_quad(s,e1,e2,r1,r0,color,Vector3(1,1,0))
	_tri(s,e0,e1,r0,color.darkened(0.12),Vector3.FORWARD)
	_tri(s,e2,e3,r1,color.darkened(0.12),Vector3.BACK)
	_quad(s,e0,e3,e2,e1,DOORWAY.lerp(color,0.3),Vector3.DOWN)

## Scale a shape into the replaced mesh's envelope exactly.
static func _fit(source:ArrayMesh,envelope:AABB)->ArrayMesh:
	var own:=source.get_aabb()
	if envelope.size.x<=0.0 or own.size.x<=0.0:return source
	var scale:=Vector3(envelope.size.x/own.size.x,envelope.size.y/maxf(own.size.y,0.001),envelope.size.z/own.size.z)
	var offset:=Vector3(envelope.get_center().x-own.get_center().x*scale.x,envelope.position.y-own.position.y*scale.y,envelope.get_center().z-own.get_center().z*scale.z)
	var arrays:=source.surface_get_arrays(0)
	var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var inverse:=Vector3(1.0/scale.x,1.0/scale.y,1.0/scale.z)
	for i in vertices.size():
		vertices[i]=vertices[i]*scale+offset
		normals[i]=(normals[i]*inverse).normalized()
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	var out:=ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return out
