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
## Fresh thatch on the domes and loaves (codex/beauty-5), a warm gold that
## still reads as straw after weathering and the map's grade.
const THATCH:=Color(0.82,0.69,0.43)
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

## How one dwelling stands (codex/beauty-5): turned to `angle`, a little
## smaller than its plot allows by its own measure (never larger, so no
## footprint grows), and leaning a degree or two the way a hand-built house
## settles. Deterministic from `seed`; `unit` scales metres to world km.
static func lived_basis(angle:float,seed:int,unit:=0.001)->Basis:
	var h:=absi(hash(seed*7919+13))
	var size:=0.86+0.115*float(h%1000)/999.0
	var stretch:=1.0+0.05*(float((h>>10)%1000)/999.0-0.5)
	var lean_axis:=Vector3(cos(float((h>>20)%628)/100.0),0.0,sin(float((h>>20)%628)/100.0))
	var lean:=deg_to_rad(0.6+1.6*float((h>>5)%100)/99.0)
	return Basis(lean_axis,lean)*Basis(Vector3.UP,angle)*Basis.from_scale(Vector3(size*stretch,size*(0.94+0.12*float((h>>15)%100)/99.0),size/stretch)*unit)

## The furniture of daily life, in metres (door or front toward +Z):
## woodpile, drying_rack, hide_frame, hearth_ring, bench, pots, quern, well,
## water_jars, midden, kiln, loom, pen_wattle, pen_stone, frame,
## timber_stack, and for markets and streets (codex/beauty-4) stall, cart and
## baskets. Cached; null for an unknown name.
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
		"stall":
			# A market stall: four poles, a striped cloth awning falling to the
			# front, a trestle board of goods beneath.
			for x in [-1.1,1.1]:
				for z in [-0.8,0.8]:
					_beam(s,Vector3(x,0,z),Vector3(x,1.95 if z<0.0 else 1.65,z),0.045,TIMBER)
			var cloth:=[Color(0.58,0.25,0.18),Color(0.76,0.70,0.56),Color(0.36,0.38,0.46)]
			var stripe:Color=cloth[0]
			for k in 6:
				var x0:=-1.25+float(k)*0.4167;var x1:=x0+0.4167
				_quad(s,Vector3(x0,2.0,-0.95),Vector3(x1,2.0,-0.95),Vector3(x1,1.62,0.98),Vector3(x0,1.62,0.98),stripe if k%2==0 else cloth[1],Vector3(0,1,0.4))
			# The board and its goods: bundles, pots and cloth.
			_box(s,Vector3(0,0.78,0.45),Vector3(2.1,0.08,0.7),TIMBER)
			for x in [-0.8,0.8]:_beam(s,Vector3(x,0,0.45),Vector3(x,0.78,0.45),0.04,TIMBER_DARK)
			for k in 5:
				var x:=-0.8+float(k)*0.4
				var tone:Color=[Color(0.66,0.46,0.28),Color(0.78,0.66,0.40),Color(0.52,0.30,0.20),Color(0.70,0.62,0.48),Color(0.40,0.46,0.28)][k]
				if k%2==0:_frustum(s,Vector3(x,0.82,0.45),0.14,0.10,0.22,6,tone,0.0)
				else:_box(s,Vector3(x,0.90,0.45),Vector3(0.28,0.16,0.34),tone)
		"cart":
			# A two-wheeled cart with its shafts down, the bed of planks.
			_box(s,Vector3(0,0.78,-0.2),Vector3(1.3,0.12,2.2),TIMBER)
			for x in [-0.62,0.62]:_box(s,Vector3(x,0.95,-0.2),Vector3(0.08,0.28,2.2),TIMBER_DARK)
			_box(s,Vector3(0,0.95,-1.28),Vector3(1.3,0.28,0.08),TIMBER_DARK)
			for x in [-0.78,0.78]:
				# Solid or spoked wheel: a rim of blocks round a hub.
				for k in 10:
					var a0:=TAU*float(k)/10.0;var a1:=TAU*float(k+1)/10.0
					_beam(s,Vector3(x,0.55+cos(a0)*0.52,-0.2+sin(a0)*0.52),Vector3(x,0.55+cos(a1)*0.52,-0.2+sin(a1)*0.52),0.05,TIMBER_DARK)
				for k in 4:
					var a:=TAU*float(k)/8.0
					_beam(s,Vector3(x,0.55+cos(a)*0.5,-0.2+sin(a)*0.5),Vector3(x,0.55-cos(a)*0.5,-0.2-sin(a)*0.5),0.03,TIMBER)
				_frustum(s,Vector3(x-0.08*signf(x),0.55,-0.2),0.12,0.12,0.16,6,TIMBER_DARK,0.0)
			for x in [-0.45,0.45]:_beam(s,Vector3(x,0.8,0.9),Vector3(x*0.7,0.08,2.3),0.05,TIMBER)
			# A load under a cloth.
			_cone_roof(s,Vector3(0,0.84,-0.3),0.6,0.2,0.45,8,Color(0.72,0.64,0.48),0.05)
		"baskets":
			for k in 4:
				var at:Vector3=[Vector3(0,0,0),Vector3(0.5,0,0.1),Vector3(0.2,0,0.5),Vector3(-0.35,0,0.35)][k]
				_frustum(s,at,0.18,0.24,0.30,8,STRAW_DARK if k%2==0 else STRAW,0.08)
				_frustum(s,at+Vector3(0,0.30,0),0.2,0.15,0.05,8,[Color(0.60,0.30,0.20),Color(0.70,0.62,0.30),Color(0.42,0.46,0.26),Color(0.66,0.50,0.30)][k],0.0)
		"dugout":
			# A log boat hauled up on the bank (codex/beauty-5): a long dark
			# hull, pointed at both ends, hollowed; a paddle laid across it.
			var hull:=[Vector2(0,-2.6),Vector2(0.28,-2.0),Vector2(0.40,-0.8),Vector2(0.42,0.6),Vector2(0.34,1.9),Vector2(0,2.5)]
			for side in [-1.0,1.0]:
				for k in hull.size()-1:
					var a:Vector2=hull[k];var b:Vector2=hull[k+1]
					_quad(s,Vector3(a.x*side,0.02,a.y),Vector3(b.x*side,0.02,b.y),Vector3(b.x*side,0.42,b.y),Vector3(a.x*side,0.42,a.y),TIMBER.darkened(0.05),Vector3(side,0.2,0))
					_quad(s,Vector3(a.x*side*0.72,0.18,a.y*0.92),Vector3(b.x*side*0.72,0.18,b.y*0.92),Vector3(b.x*side,0.42,b.y),Vector3(a.x*side,0.42,a.y),TIMBER_DARK.darkened(0.2),Vector3(-side,1,0))
			# The hollowed floor, dark with old water.
			for k in hull.size()-1:
				var a:Vector2=hull[k];var b:Vector2=hull[k+1]
				_quad(s,Vector3(-a.x*0.72,0.18,a.y*0.92),Vector3(a.x*0.72,0.18,a.y*0.92),Vector3(b.x*0.72,0.18,b.y*0.92),Vector3(-b.x*0.72,0.18,b.y*0.92),TIMBER_DARK.darkened(0.35),Vector3.UP)
			_beam(s,Vector3(-0.7,0.46,0.3),Vector3(0.8,0.46,-0.2),0.04,TIMBER)
			_box(s,Vector3(0.95,0.46,-0.28),Vector3(0.34,0.03,0.16),TIMBER)
		"coracle":
			# A round boat of hide on a woven frame, turned over to dry.
			_cone_roof(s,Vector3.ZERO,0.85,0.45,0.42,12,HIDE_DARK,0.06)
			_frustum(s,Vector3(0,0.42,0),0.45,0.0,0.02,12,HIDE_DARK.darkened(0.1),0.0)
		"weir":
			# A fish weir: a V of stakes and woven wattle across the stream,
			# its point downstream (+Z) where the trap basket sits.
			for side in [-1.0,1.0]:
				var a:=Vector3(side*5.5,0,-3.5);var b:=Vector3(0,0,1.5)
				for k in 10:
					var p:=a.lerp(b,float(k)/9.0)
					_beam(s,p+Vector3(0,-0.4,0),p+Vector3(0,0.9,0),0.06,TIMBER_DARK)
				_beam(s,a+Vector3(0,0.45,0),b+Vector3(0,0.45,0),0.09,BARK.lerp(STRAW_DARK,0.3))
			_frustum(s,Vector3(0,0.0,2.1),0.45,0.30,0.7,8,STRAW_DARK,0.05)
		"jetty":
			# A landing stage: planks on posts, running out from the bank (-Z)
			# over the water (+Z), a mooring post at its end.
			for k in 4:
				var z:=float(k)*2.4
				for x in [-0.8,0.8]:_beam(s,Vector3(x,-0.6,z),Vector3(x,0.55,z),0.09,TIMBER_DARK)
			for k in 9:
				_box(s,Vector3(0,0.52,-0.5+float(k)*0.95),Vector3(1.9,0.07,0.85),TIMBER.lightened(0.04*float(k%2)))
			_beam(s,Vector3(0.7,0.2,8.0),Vector3(0.7,1.2,8.0),0.1,TIMBER_DARK)
		"quay":
			# A stone landing: dressed blocks along the bank, steps down to the water.
			for k in 7:
				_box(s,Vector3(float(k)*1.2-3.6,0.35,0),Vector3(1.15,0.7,1.6),Color(0.60,0.57,0.51).darkened(0.05*float(k%3)))
			for step in 3:
				_box(s,Vector3(0,0.55-float(step)*0.22,1.0+float(step)*0.45),Vector3(1.6,0.2,0.45),Color(0.55,0.52,0.47))
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

## Round five (codex/beauty-5): the early dwellings are drawn to be read from
## above. A round house is a bellied dome of thatch laid in courses, patched
## where it was mended, bound at a thick cut eave, with a dark smoke hole at
## its crown and a small hooded porch over the door (a nub on the circle that
## shows which way the door looks). A timber house is a long loaf of thatch
## with rounded hips, the ridge bound and vented at both ends, a porch at its
## gable door. The wattle wall shows below the eave on the side toward the
## viewer. Smooth-shaded so the thatch reads as a soft mass, not facets.
static func _round_house(s:SurfaceTool)->void:
	var sides:=28
	# Wattle wall: stakes and daub, alternating a little in tone; a line of
	# upright stakes shows through the daub.
	_ring_wall(s,1.50,0.0,1.05,sides,WATTLE,0.10)
	for k in 14:
		var a:=TAU*(float(k)+0.5)/14.0
		if absf(wrapf(a,-PI,PI))<0.45:continue
		_box(s,Vector3(sin(a)*1.52,0.52,cos(a)*1.52),Vector3(0.07,1.04,0.07),TIMBER.lerp(WATTLE,0.35))
	# The thatch dome: eave at 1.05 m, crown at 3.0 m, bellied, with a smoke
	# hole at the top and a thick cut edge at the eave.
	_thatch_dome(s,1.02,3.05,Vector2(1.92,1.92),0.0,sides,7,THATCH,0.30,1.0)
	# The hooded porch over the door, toward +Z.
	_porch(s,Vector3(0,0,1.40),1.05,0.95,1.35,STRAW)

static func _thatched_house(s:SurfaceTool,variant:String)->void:
	# A timber-framed, wattle-walled house under a long loaf of thatch.
	var length:=7.0
	var width:=4.0
	match variant:
		"house_narrow":length=7.2;width=3.6
		"house_compact":length=6.0;width=4.2
		"house_medium":length=5.6;width=4.8
		"house_wide":length=5.0;width=5.4
		"house_small":length=4.2;width=3.6
	var wall_h:=1.45
	# Walls (long axis along Z), a darker sill course and corner posts.
	_box(s,Vector3(0,wall_h*0.5,0),Vector3(width-0.5,wall_h,length-0.5),WATTLE)
	_box(s,Vector3(0,0.12,0),Vector3(width-0.42,0.24,length-0.42),TIMBER)
	for x in [-1,1]:
		for z in [-1,1]:
			_box(s,Vector3(x*(width*0.5-0.25),wall_h*0.5,z*(length*0.5-0.25)),Vector3(0.16,wall_h,0.16),TIMBER)
	# A second door on the long side.
	_box(s,Vector3(width*0.5-0.23,0.6,0.4),Vector3(0.06,1.15,0.8),DOORWAY)
	# The thatch: a long rounded loaf over deep eaves, the ridge along Z.
	var eave:=Vector2(width*0.5+0.40,length*0.5+0.40)
	var ridge_half:=maxf(eave.y-eave.x*0.95,0.25)
	var top:=wall_h+width*0.55+0.75
	_thatch_dome(s,wall_h-0.05,top,eave,ridge_half,32,6,THATCH.darkened(0.03),0.0,1.6)
	# The ridge bound with a roll of darker straw; smoke vents at both ends.
	_beam(s,Vector3(0,top+0.02,-ridge_half-0.2),Vector3(0,top+0.02,ridge_half+0.2),0.13,STRAW_DARK)
	for z in [-1.0,1.0]:
		_box(s,Vector3(0,top-0.10,z*(ridge_half+0.30)),Vector3(0.46,0.26,0.30),DOORWAY)
	# A porch over the gable door, toward +Z.
	_porch(s,Vector3(0,0,length*0.5-0.30),1.15,1.0,1.40,STRAW)

## A dome (or, with `ridge_half` > 0, a loaf along Z) of thatch from eave
## height `y0` to crown `y1` over half-extents `eave` (x, z). Rounded-square
## in plan (a superellipse), bellied in section, laid in `rings` courses that
## alternate a little in tone, with mended patches. `hole` > 0 leaves a smoke
## hole of that radius at the crown, ringed by a collar. `belly` shapes the
## section (1 a dome, higher a fuller loaf). Smooth normals.
static func _thatch_dome(s:SurfaceTool,y0:float,y1:float,eave:Vector2,ridge_half:float,sides:int,rings:int,color:Color,hole:float,belly:float)->void:
	var n:=2.5 if ridge_half>0.0 else 2.0
	var ez:=maxf(eave.y-ridge_half,0.1)
	var t0:=hole/maxf(eave.x,0.1) if hole>0.0 else 0.0
	var grid:Array=[]
	var normals:Array=[]
	var tones:Array=[]
	var count:=rings+2
	for r in count:
		var row:=PackedVector3Array();var shade:=PackedColorArray()
		# The last ring is the cut lip: a little out and down from the eave.
		var lip:=r==count-1
		var t:=1.05 if lip else lerpf(t0,1.0,float(r)/float(rings))
		var profile:=pow(maxf(1.0-minf(t,1.0)*minf(t,1.0),0.0),0.55/belly)
		var y:=(y0-0.16) if lip else y0+(y1-y0)*profile
		for k in sides:
			var a:=TAU*float(k)/float(sides)
			var c:=sin(a);var d:=cos(a)
			var sx:=signf(c)*pow(absf(c),2.0/n);var sz:=signf(d)*pow(absf(d),2.0/n)
			# A little uneven, the way hand-laid straw lies.
			var wobble:=1.0+0.028*sin(a*3.0+1.3)+0.016*sin(a*7.0-0.4)
			var p:=Vector3(eave.x*t*sx*wobble,y,ez*t*sz*wobble+ridge_half*clampf(d*2.5,-1.0,1.0))
			row.append(p)
			# Courses alternate in tone; a mended sector is paler and fresher.
			var tone:=color.darkened(0.07 if r%2==1 else 0.0)
			var mend:=smoothstep(0.55,0.95,sin(a*2.0+0.7)*0.5+0.5)*(0.5+0.5*sin(float(r)*1.7))
			tone=tone.lerp(color.lightened(0.12),mend*0.55)
			if lip:tone=STRAW_DARK.darkened(0.08)
			elif r==count-2:tone=STRAW_DARK
			shade.append(tone)
		grid.append(row);tones.append(shade)
	# Smooth normals from the neighbouring rings and sides.
	for r in count:
		var row:PackedVector3Array=grid[r];var nrow:=PackedVector3Array()
		for k in sides:
			var along:Vector3=row[(k+1)%sides]-row[(k-1+sides)%sides]
			var up_row:PackedVector3Array=grid[maxi(r-1,0)];var down_row:PackedVector3Array=grid[mini(r+1,count-1)]
			var down:Vector3=down_row[k]-up_row[k]
			var normal:=along.cross(down).normalized()
			if normal.y<0.0 and r<count-1:normal=-normal
			var outward:=Vector3(row[k].x,0.0,row[k].z-ridge_half*clampf(row[k].z,-1.0,1.0))
			if normal.dot(outward)<0.0 and normal.y<0.2:normal=-normal
			nrow.append(normal)
		normals.append(nrow)
	for r in count-1:
		var a_row:PackedVector3Array=grid[r];var b_row:PackedVector3Array=grid[r+1]
		var na:PackedVector3Array=normals[r];var nb:PackedVector3Array=normals[r+1]
		var ca:PackedColorArray=tones[r];var cb:PackedColorArray=tones[r+1]
		for k in sides:
			var j:=(k+1)%sides
			_tri_smooth(s,a_row[k],a_row[j],b_row[j],na[k],na[j],nb[j],ca[k],ca[j],cb[j])
			_tri_smooth(s,a_row[k],b_row[j],b_row[k],na[k],nb[j],nb[k],ca[k],cb[j],cb[k])
	# Courses of thatch: a few crisp darker lines where one course laps the
	# next, just proud of the surface, so the dome reads as laid straw.
	for r in range(2,count-2,2):
		var row:PackedVector3Array=grid[r];var below:PackedVector3Array=grid[r+1]
		var nrow:PackedVector3Array=normals[r]
		for k in sides:
			var j:=(k+1)%sides
			var a0:Vector3=row[k]+nrow[k]*0.03;var a1:Vector3=row[j]+nrow[j]*0.03
			var b0:Vector3=row[k].lerp(below[k],0.22)+nrow[k]*0.03;var b1:Vector3=row[j].lerp(below[j],0.22)+nrow[j]*0.03
			var line:=color.darkened(0.24)
			_tri_smooth(s,a0,a1,b1,nrow[k],nrow[j],nrow[j],line,line,line)
			_tri_smooth(s,a0,b1,b0,nrow[k],nrow[j],nrow[k],line,line,line)
	# The underside of the lip, in shade.
	var lip_row:PackedVector3Array=grid[count-1]
	for k in sides:
		var j:=(k+1)%sides
		var inner_a:=Vector3(lip_row[k].x*0.82,y0-0.10,lip_row[k].z*0.82)
		var inner_b:=Vector3(lip_row[j].x*0.82,y0-0.10,lip_row[j].z*0.82)
		_quad(s,lip_row[k],lip_row[j],inner_b,inner_a,DOORWAY.lerp(STRAW_DARK,0.35),Vector3.DOWN)
	if hole>0.0:
		# The smoke hole: a dark mouth ringed by a bound collar.
		var crown:PackedVector3Array=grid[0]
		var middle:=Vector3(0,crown[0].y-0.05,0)
		for k in sides:
			_tri(s,crown[k],crown[(k+1)%sides],middle,Color(0.07,0.055,0.045),Vector3.UP)
		for k in sides:
			var a:=TAU*float(k)/float(sides);var b:=TAU*float(k+1)/float(sides)
			var r0:=hole*1.0;var r1:=hole*1.45
			var y:=crown[0].y
			_quad(s,Vector3(sin(a)*r0,y+0.10,cos(a)*r0),Vector3(sin(b)*r0,y+0.10,cos(b)*r0),Vector3(sin(b)*r1,y+0.02,cos(b)*r1),Vector3(sin(a)*r1,y+0.02,cos(a)*r1),TIMBER_DARK.lerp(STRAW_DARK,0.4),Vector3.UP)

## A small hooded porch standing out from a wall at `at` (its back), toward
## +Z: two posts, a steep little gable of thatch, a dark doorway under it.
static func _porch(s:SurfaceTool,at:Vector3,depth:float,width:float,height:float,color:Color)->void:
	var front:=at.z+depth
	for x in [-width*0.42,width*0.42]:
		_beam(s,Vector3(x,0,front-0.08),Vector3(x,height,front-0.08),0.05,TIMBER)
	_box(s,Vector3(0,height*0.46,at.z+0.10),Vector3(width*0.62,height*0.92,0.10),DOORWAY)
	var hw:=width*0.62
	var ridge:=height+0.55
	var e0:=Vector3(-hw,height,at.z-0.1);var e1:=Vector3(-hw,height,front+0.12)
	var e2:=Vector3(hw,height,front+0.12);var e3:=Vector3(hw,height,at.z-0.1)
	var r0:=Vector3(0,ridge,at.z-0.3);var r1:=Vector3(0,ridge,front+0.12)
	_quad(s,e0,e1,r1,r0,color.darkened(0.04),Vector3(-1,1,0))
	_quad(s,e3,e2,r1,r0,color,Vector3(1,1,0))
	_tri(s,e1,e2,r1,DOORWAY.lerp(color,0.25),Vector3.BACK)
	_beam(s,r0,r1,0.06,STRAW_DARK)

## One smooth-shaded triangle: the face is turned outward (its own normals'
## sum) and wound clockwise as seen from that side, as _tri does.
static func _tri_smooth(s:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,na:Vector3,nb:Vector3,nc:Vector3,ca:Color,cb:Color,cc:Color)->void:
	var face:=(b-a).cross(c-a)
	if face.length_squared()<1e-12:return
	var hint:=na+nb+nc
	if face.dot(hint)>0.0:
		var t:=b;b=c;c=t
		var tn:=nb;nb=nc;nc=tn
		var tc:=cb;cb=cc;cc=tc
	s.set_color(ca);s.set_normal(na);s.add_vertex(a)
	s.set_color(cb);s.set_normal(nb);s.add_vertex(b)
	s.set_color(cc);s.set_normal(nc);s.add_vertex(c)

static func _granary(s:SurfaceTool)->void:
	# A round store on stilts, out of reach of damp and vermin: a woven drum
	# plastered with daub under a little cap of thatch with a knot at its top.
	for k in 5:
		var a:=TAU*float(k)/5.0+0.3
		var at:=Vector3(sin(a)*0.95,0,cos(a)*0.95)
		_box(s,at+Vector3(0,0.45,0),Vector3(0.16,0.9,0.16),TIMBER_DARK)
		# Rat stones: flat caps on the stilts.
		_frustum(s,at+Vector3(0,0.86,0),0.26,0.22,0.08,8,Color(0.55,0.52,0.46),0.0)
	_frustum(s,Vector3(0,0.94,0),1.25,1.25,0.12,14,TIMBER,0.0)
	_ring_wall(s,1.08,1.06,2.02,16,WATTLE.lerp(DAUB,0.5),0.10)
	_box(s,Vector3(0,1.55,1.06),Vector3(0.55,0.6,0.06),DOORWAY)
	# Ladder up to the hatch.
	for x in [-0.25,0.25]:
		_beam(s,Vector3(x,0.0,1.9),Vector3(x,1.2,1.12),0.06,TIMBER)
	for k in 4:
		var t:=(float(k)+0.6)/4.6
		_box(s,Vector3(0,t*1.2,lerpf(1.9,1.12,t)),Vector3(0.56,0.05,0.07),TIMBER)
	_thatch_dome(s,1.96,3.05,Vector2(1.45,1.45),0.0,20,4,THATCH,0.0,0.9)
	# The top knot.
	_frustum(s,Vector3(0,2.98,0),0.20,0.05,0.34,8,STRAW_DARK,0.0)

static func _work_shelter(s:SurfaceTool)->void:
	# Posts under a loaf of thatch, open on every side, a work log beneath.
	for x in [-1,1]:
		for z in [-1,0,1]:
			_box(s,Vector3(x*1.25,0.85,z*1.25),Vector3(0.13,1.7,0.13),TIMBER)
	_thatch_dome(s,1.62,2.75,Vector2(1.60,1.75),0.35,24,4,THATCH.darkened(0.05),0.0,1.4)
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
	var sides:=16
	_cone_roof(s,Vector3.ZERO,1.55,0.0,2.45,sides,HIDE,0.07)
	# Sewn seams between the hides, running from the ground to the crown.
	for k in 7:
		var a:=TAU*(float(k)+0.35)/7.0
		if absf(wrapf(a,-PI,PI))<0.4:continue
		var dir:=Vector3(sin(a),0,cos(a))
		for j in 4:
			# Follow the hides' belly (as _cone_roof lays them), just proud of it.
			var t0:=float(j)/4.0;var t1:=float(j+1)/4.0
			var p0:=dir*(lerpf(1.55,0.0,t0)+sin(t0*PI)*0.10+0.03)+Vector3(0,2.45*t0,0)
			var p1:=dir*(lerpf(1.55,0.0,t1)+sin(t1*PI)*0.10+0.03)+Vector3(0,2.45*t1,0)
			_beam(s,p0,p1,0.035,HIDE_DARK.darkened(0.28))
	# The door flap turned back: a dark opening, the flap's lighter underside.
	_tri(s,Vector3(-0.42,0.02,1.45),Vector3(0.42,0.02,1.45),Vector3(0,1.25,0.95),DOORWAY,Vector3.BACK)
	_tri(s,Vector3(0.42,0.02,1.47),Vector3(0.80,0.10,1.25),Vector3(0.05,1.22,0.99),HIDE.lightened(0.12),Vector3(1,0.3,1))
	# The smoke flaps at the crown, open to the wind, and the pole tips above.
	_tri(s,Vector3(-0.30,2.05,0.20),Vector3(0.0,2.55,0.05),Vector3(-0.55,2.55,0.40),HIDE_DARK,Vector3(-1,0.5,1))
	_tri(s,Vector3(0.30,2.05,0.20),Vector3(0.0,2.55,0.05),Vector3(0.55,2.55,0.40),HIDE_DARK.darkened(0.1),Vector3(1,0.5,1))
	for k in 7:
		var a:=TAU*float(k)/7.0+0.3
		_beam(s,Vector3(sin(a)*0.42,1.95,cos(a)*0.42),Vector3(-sin(a)*0.30,3.15,-cos(a)*0.30),0.04,TIMBER_DARK)
	# A painted band round the hides.
	_frustum(s,Vector3(0,0.55,0),1.22,1.16,0.12,sides,HIDE_DARK,0.0)
	# Pegs round the foot.
	for k in 10:
		var a:=TAU*(float(k)+0.5)/10.0
		_box(s,Vector3(sin(a)*1.66,0.06,cos(a)*1.66),Vector3(0.08,0.12,0.08),TIMBER_DARK)

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
