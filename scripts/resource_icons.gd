extends RefCounted
## Procedural map icons for recognized resource occurrences. Every catalog
## resource gets a distinct silhouette rendered once at runtime and cached, so
## the map overlay can identify deposits without stacking text labels.

const ICON_PX:=56

static var _textures:Dictionary={}


static var _domain_textures:Dictionary={}


static func texture_for(resource_name:String)->Texture2D:
	if _textures.has(resource_name): return _textures[resource_name]
	var texture:=ImageTexture.create_from_image(_render(_glyph(resource_name)))
	_textures[resource_name]=texture
	return texture


# -- primitive constructors -------------------------------------------------

static func _c(x:float,y:float,r:float,col:Color)->Dictionary: return {"k":0,"a":Vector2(x,y),"r":r,"col":col}
static func _ring(x:float,y:float,r:float,w:float,col:Color)->Dictionary: return {"k":1,"a":Vector2(x,y),"r":r,"w":w,"col":col}
static func _s(x1:float,y1:float,x2:float,y2:float,w:float,col:Color)->Dictionary: return {"k":2,"a":Vector2(x1,y1),"b":Vector2(x2,y2),"r":w*0.5,"col":col}
static func _t(ax:float,ay:float,bx:float,by:float,cx:float,cy:float,col:Color)->Dictionary: return {"k":3,"a":Vector2(ax,ay),"b":Vector2(bx,by),"c":Vector2(cx,cy),"col":col}
static func _rr(x:float,y:float,hw:float,hh:float,rad:float,col:Color)->Dictionary: return {"k":4,"a":Vector2(x,y),"b":Vector2(hw,hh),"r":rad,"col":col}
static func _d(x:float,y:float,s:float,col:Color)->Dictionary: return {"k":5,"a":Vector2(x,y),"r":s,"col":col}
## A bar from (x1, y1) to (x2, y2), w wide, with square ends (a gun barrel,
## a rail, a launcher pod at an angle).
static func _ob(x1:float,y1:float,x2:float,y2:float,w:float,col:Color)->Dictionary: return {"k":6,"a":Vector2(x1,y1),"b":Vector2(x2,y2),"r":w*0.5,"col":col}
## A filled polygon from flat coordinates [x1, y1, x2, y2, ...] (a hull, a
## sloped glacis, a wedge turret, a canopy).
static func _poly(coords:Array,col:Color)->Dictionary:
	var points:=PackedVector2Array()
	for i in range(0,coords.size()-1,2): points.append(Vector2(float(coords[i]),float(coords[i+1])))
	return {"k":7,"a":points[0],"pts":points,"col":col}


# -- signed distance evaluation --------------------------------------------

static func _sd(primitive:Dictionary,p:Vector2)->float:
	match int(primitive.k):
		0: return p.distance_to(primitive.a)-float(primitive.r)
		1: return absf(p.distance_to(primitive.a)-float(primitive.r))-float(primitive.w)*0.5
		2:
			var a:Vector2=primitive.a
			var ba:Vector2=(primitive.b as Vector2)-a
			var h:=clampf((p-a).dot(ba)/maxf(0.0001,ba.length_squared()),0.0,1.0)
			return (p-a-ba*h).length()-float(primitive.r)
		3:
			var a:Vector2=primitive.a; var b:Vector2=primitive.b; var c:Vector2=primitive.c
			var e0:=b-a; var e1:=c-b; var e2:=a-c
			var v0:=p-a; var v1:=p-b; var v2:=p-c
			var pq0:=v0-e0*clampf(v0.dot(e0)/maxf(0.0001,e0.length_squared()),0.0,1.0)
			var pq1:=v1-e1*clampf(v1.dot(e1)/maxf(0.0001,e1.length_squared()),0.0,1.0)
			var pq2:=v2-e2*clampf(v2.dot(e2)/maxf(0.0001,e2.length_squared()),0.0,1.0)
			var s:=signf(e0.x*e2.y-e0.y*e2.x)
			var d:=minf(minf(pq0.length_squared(),pq1.length_squared()),pq2.length_squared())
			var side:=minf(minf(s*(v0.x*e0.y-v0.y*e0.x),s*(v1.x*e1.y-v1.y*e1.x)),s*(v2.x*e2.y-v2.y*e2.x))
			return sqrt(d)*(-1.0 if side>0.0 else 1.0)
		4:
			var q:=(p-(primitive.a as Vector2)).abs()-(primitive.b as Vector2)+Vector2.ONE*float(primitive.r)
			return Vector2(maxf(q.x,0.0),maxf(q.y,0.0)).length()+minf(maxf(q.x,q.y),0.0)-float(primitive.r)
		5:
			var q:=p-(primitive.a as Vector2)
			return (absf(q.x)+absf(q.y)-float(primitive.r))*0.7071
		6:
			var a:Vector2=primitive.a
			var along:=(primitive.b as Vector2)-a
			var length:=maxf(0.0001,along.length())
			var dir:=along/length
			var q:=p-(a+(primitive.b as Vector2))*0.5
			var local:=Vector2(absf(q.dot(dir)),absf(q.dot(dir.orthogonal())))-Vector2(length*0.5,float(primitive.r))
			return Vector2(maxf(local.x,0.0),maxf(local.y,0.0)).length()+minf(maxf(local.x,local.y),0.0)
		7:
			var points:PackedVector2Array=primitive.pts
			var d:=(p-points[0]).length_squared()
			var s:=1.0
			var j:=points.size()-1
			for i in points.size():
				var e:=points[j]-points[i]
				var w:=p-points[i]
				var b:=w-e*clampf(w.dot(e)/maxf(0.0001,e.length_squared()),0.0,1.0)
				d=minf(d,b.length_squared())
				var c1:=p.y>=points[i].y; var c2:=p.y<points[j].y; var c3:=e.x*w.y>e.y*w.x
				if (c1 and c2 and c3) or (not c1 and not c2 and not c3): s=-s
				j=i
			return s*sqrt(d)
	return 1e6


static func _render(primitives:Array,px:int=ICON_PX,disc:bool=true)->Image:
	## Glyphs are designed on the 56px grid; larger sizes re-evaluate the same
	## distance field so card-sized marks stay crisp instead of upscaled.
	## Without the disc a glyph stands alone (small figures in a row).
	var image:=Image.create(px,px,false,Image.FORMAT_RGBA8)
	var scale:=float(px)/float(ICON_PX)
	var stack:Array=[
		_c(28,28,25,Color(0.035,0.066,0.060,0.88)),
		_ring(28,28,24.0,1.6,Color(0.87,0.82,0.70,0.55)),
	] if disc else []
	stack.append_array(primitives)
	for y in px:
		for x in px:
			var p:=Vector2(x+0.5,y+0.5)/scale
			var out:=Color(0,0,0,0)
			for primitive_variant in stack:
				var primitive:Dictionary=primitive_variant
				var coverage:=clampf(0.5-_sd(primitive,p)*scale,0.0,1.0)*(primitive.col as Color).a
				if coverage<=0.0: continue
				var col:Color=primitive.col
				out.r=lerpf(out.r,col.r,coverage)
				out.g=lerpf(out.g,col.g,coverage)
				out.b=lerpf(out.b,col.b,coverage)
				out.a=out.a+(1.0-out.a)*coverage
			image.set_pixel(x,y,out)
	image.generate_mipmaps()
	return image


# -- glyph library ----------------------------------------------------------

static func _ore_rock(dot_color:Color)->Array:
	return [
		_c(26,32,11,Color("#6f6a64")),
		_c(34,28,8,Color("#7d7871")),
		_c(23,30,2.6,dot_color),
		_c(31,25,2.6,dot_color),
		_c(30,35,2.6,dot_color),
	]


static func _pot(body:Color,rim:Color)->Array:
	return [
		_rr(28,34,11,8,5,body),
		_rr(28,23,13,3,2,rim),
	]


static func _droplet(fill:Color,shine:Color)->Array:
	return [
		_t(28,10,17,32,39,32,fill),
		_c(28,33,11,fill),
		_c(24,34,3,shine),
	]


static func _glyph(resource_name:String)->Array:
	match resource_name:
		"Timber": return [
			_s(28,40,28,47,3,Color("#7a5230")),
			_t(28,20,14,40,42,40,Color("#3f7a3e")),
			_t(28,9,16,29,40,29,Color("#4f8f4a")),
		]
		"Freshwater": return _droplet(Color("#4da3d8"),Color("#a8d8ef"))
		"Deep Aquifer": return [
			_rr(28,16,2.5,6,1,Color("#58b0d8")),
			_t(28,32,19,22,37,22,Color("#58b0d8")),
			_s(15,38,41,38,2.5,Color("#4da3d8")),
			_s(18,44,38,44,2.5,Color("#3d8cbc")),
		]
		"Stone": return [
			_c(24,32,10,Color("#8a8f8c")),
			_c(33,30,8,Color("#9aa09c")),
			_rr(28,39,12,4,3,Color("#7c817e")),
		]
		"Fertile Soil": return [
			_rr(28,40,14,5,4,Color("#6b4a2e")),
			_s(28,36,28,20,2,Color("#5da04f")),
			_s(28,30,20,24,3,Color("#5da04f")),
			_s(28,26,36,20,3,Color("#6fb15c")),
		]
		"Game": return [
			_c(28,34,8,Color("#c49a5e")),
			_c(18,24,3.5,Color("#c49a5e")),
			_c(28,19,3.5,Color("#c49a5e")),
			_c(38,24,3.5,Color("#c49a5e")),
		]
		"Fiber Plants": return [
			_s(28,45,28,17,2.5,Color("#86b45c")),
			_s(27,45,17,22,2.5,Color("#76a54e")),
			_s(29,45,39,22,2.5,Color("#96c46a")),
		]
		"Clay": return _pot(Color("#b06a3e"),Color("#c07a4a"))
		"Refractory Clay": return _pot(Color("#d8c7a8"),Color("#e4d6bc"))
		# Arms (weapons_stock.gd): a spear crossed with a strung bow.
		"Arms": return [
			_s(12,46,38,16,2.6,Color("#7a5230")),
			_t(46,8,34,14,40,21,Color("#4a4f52")),
			_s(16,10,16,46,1.2,Color("#5a4632")),
			_s(16,10,24,20,2.2,Color("#8a6040")),
			_s(24,20,24,36,2.2,Color("#8a6040")),
			_s(24,36,16,46,2.2,Color("#8a6040")),
		]
		"Flint": return [
			_t(28,10,18,41,38,41,Color("#4a4f52")),
			_t(28,17,22,37,34,37,Color("#6a7075")),
		]
		"Salt": return [
			_d(28,28,16,Color("#e8e6df")),
			_d(28,28,9,Color("#c9c7be")),
		]
		"Medicinal Plants": return [
			_rr(28,28,4,12,3,Color("#7fc9a0")),
			_rr(28,28,12,4,3,Color("#7fc9a0")),
		]
		"Peat": return [
			_rr(28,23,12,5,2,Color("#4a382a")),
			_rr(28,35,12,5,2,Color("#5c4634")),
		]
		"Limestone": return [
			_rr(28,18,13,3.5,2,Color("#cfcabb")),
			_rr(28,28,13,3.5,2,Color("#bcb6a6")),
			_rr(28,38,13,3.5,2,Color("#a8a294")),
		]
		"Copper Ore": return _ore_rock(Color("#d97f3f"))
		"Tin Ore": return _ore_rock(Color("#cfd4d8"))
		"Lead Ore": return _ore_rock(Color("#5d6b7d"))
		"Iron Ore": return _ore_rock(Color("#b0503a"))
		"Zinc Ore": return _ore_rock(Color("#9fb3b8"))
		"Kaolin": return _pot(Color("#eeeae0"),Color("#f7f4ec"))
		"Phosphate Rock": return _ore_rock(Color("#cdd08a"))
		"Bitumen": return _droplet(Color("#1f2224"),Color("#4a5054"))
		"Fine Sand": return [
			_t(28,22,12,44,44,44,Color("#d3b078")),
			_c(24,38,1.6,Color("#b3905c")),
			_c(32,40,1.6,Color("#b3905c")),
			_c(28,33,1.6,Color("#b3905c")),
		]
		"Coal": return [
			_c(22,30,7,Color("#23262a")),
			_c(34,30,7,Color("#23262a")),
			_c(28,38,7,Color("#2b2f34")),
			_c(25,27,2,Color("#4d525a")),
		]
		"Sulfur": return [
			_t(24,12,16,40,32,40,Color("#e3c531")),
			_t(36,20,28,44,44,44,Color("#c9ad22")),
		]
		"Nitrates": return [
			_d(20,30,6,Color("#dfe6d2")),
			_d(32,22,6,Color("#cdd8be")),
			_d(34,36,6,Color("#dfe6d2")),
		]
		"Graphite": return [
			_c(26,32,11,Color("#3a3f44")),
			_c(32,26,6,Color("#545a61")),
			_s(18,42,40,16,3,Color("#767d85")),
		]
	return [_c(28,28,10,Color("#b9b7ae"))]


# -- society-dynamic glyphs --------------------------------------------------
# One glyph per canonical dynamic, tinted with the caller's domain accent so
# knowledge, investigation, and society views share a single visual language.

static func domain_texture(domain_id:String,accent:Color)->Texture2D:
	var key:="%s|%s" % [domain_id,accent.to_html()]
	if _domain_textures.has(key): return _domain_textures[key]
	var texture:=ImageTexture.create_from_image(_render(_domain_glyph(domain_id,accent)))
	_domain_textures[key]=texture
	return texture


static func _domain_glyph(domain_id:String,c:Color)->Array:
	var hi:=c.lightened(0.28)
	match domain_id:
		"demography": return [_c(28,19,6,c),_t(28,26,17,44,39,44,c)]
		"nutrition": return [
			_s(28,45,28,18,2.5,c),_s(26,45,18,24,2.5,c),_s(30,45,38,24,2.5,c),
			_c(28,16,3,hi),_c(18,22,3,hi),_c(38,22,3,hi),
		]
		"health": return [_rr(28,28,4,12,3,c),_rr(28,28,12,4,3,c)]
		"labor": return [_rr(28,19,11,5,2,c),_s(28,24,28,45,3,hi)]
		"knowledge": return [_rr(20.5,30,7,9.5,1,c),_rr(35.5,30,7,9.5,1,c),_s(28,20,28,40,1.6,hi)]
		"production": return [
			_ring(28,28,9,4.5,c),_c(28,28,3,hi),
			_c(28,15,3,c),_c(28,41,3,c),_c(15,28,3,c),_c(41,28,3,c),
			_c(19,19,2.6,c),_c(37,19,2.6,c),_c(19,37,2.6,c),_c(37,37,2.6,c),
		]
		"infrastructure": return [_t(28,12,13,30,43,30,c),_rr(28,37,10,7,1,hi)]
		"logistics": return [_rr(28,26,12,6,2,c),_c(21,38,4,hi),_c(35,38,4,hi)]
		"ecology": return [_c(31,25,9,c),_s(19,43,29,29,2,hi)]
		"institutions": return [
			_rr(19,30,2.5,9,1,c),_rr(28,30,2.5,9,1,c),_rr(37,30,2.5,9,1,c),
			_rr(28,17,13,3,1,hi),_rr(28,43,13,3,1,hi),
		]
		"security": return [_rr(28,24,10,8,3,c),_t(18,31,38,31,28,45,c)]
		"culture": return [_s(21,12,21,45,2,hi),_t(21,14,41,20,21,27,c)]
		"wealth": return [_rr(28,39,11,3.2,2.5,c),_rr(28,32,11,3.2,2.5,hi),_rr(28,25,11,3.2,2.5,c),_ring(28,16,6.5,2.2,hi)]
	return [_c(28,28,10,c)]


# -- Chronicle moments ------------------------------------------------------

static var _moment_textures:Dictionary={}

## One mark per kind of remembered moment (scripts/chronicle.gd), drawn at card
## size. Kinds without a mark fall back to the hearth fire.
static func moment_texture(kind:String,accent:Color,px:int=112)->Texture2D:
	var key:="%s|%s|%d" % [kind,accent.to_html(),px]
	if _moment_textures.has(key): return _moment_textures[key]
	var texture:=ImageTexture.create_from_image(_render(_moment_glyph(kind,accent),px))
	_moment_textures[key]=texture
	return texture


static func _moment_glyph(kind:String,c:Color)->Array:
	var hi:=c.lightened(0.30)
	var dim:=c.darkened(0.35)
	match kind:
		"birth": return [_c(22,16,5,c),_rr(22,31,6.5,11,4,c),_c(35,27,3.6,hi),_rr(35,36,4.2,6,3,hi),_s(26,28,32,33,2.4,c),_s(10,45,46,45,1.6,dim)]
		"death": return [_rr(28,41,13,3.5,2,dim),_rr(28,34,9,3.5,2,c),_rr(28,27,6,3,2,c),_c(28,20,3.5,hi)]
		"discovery": return [_d(28,27,11,hi),_s(28,10,28,44,1.6,c),_s(11,27,45,27,1.6,c),_c(28,27,3,Color(1,1,1,0.9))]
		"contact": return [_c(19,20,4.5,c),_rr(19,33,5,9,3,c),_c(37,20,4.5,hi),_rr(37,33,5,9,3,hi),_s(23,29,33,29,2.4,hi)]
		"settlement": return [_t(18,22,9,32,27,32,c),_rr(18,37,7,5,1,c),_t(38,26,31,34,45,34,hi),_rr(38,38,5,4,1,hi),_s(10,44,46,44,1.6,dim)]
		"ceremony": return [_rr(28,31,5,13,2,hi),_rr(17,35,3.5,9,1.5,c),_rr(39,35,3.5,9,1.5,c),_ring(28,14,5,1.8,hi),_s(10,45,46,45,1.6,dim)]
		"milestone": return [_c(28,34,10,hi),_rr(28,42,19,6,0,Color(0.035,0.066,0.060,1)),_s(28,14,28,19,2,c),_s(15,21,18,24,2,c),_s(41,21,38,24,2,c),_s(10,40,46,40,1.8,c)]
		"scout": return [_rr(22,34,4,6,3,c),_c(22,25,2.2,c),_rr(34,24,4,6,3,hi),_c(34,15,2.2,hi),_s(12,44,44,12,1.2,dim)]
		"omen": return [_c(30,24,10,hi),_c(35,21,9,Color(0.035,0.066,0.060,1)),_c(20,38,5,c),_c(28,36,6,c),_c(36,38,5,c)]
		"war": return [_s(14,42,40,14,2.6,c),_s(42,42,16,14,2.6,c),_t(40,14,44,10,36,12,hi),_t(16,14,12,10,20,12,hi)]
		"court": return [_ring(28,30,13,2.4,c),_t(28,20,23,33,33,33,hi),_c(28,31,3,Color(1,0.9,0.6,0.95))]
		"hearth_count": return [_s(15,16,15,40,2.4,c),_s(21,16,21,40,2.4,c),_s(27,16,27,40,2.4,c),_s(33,16,33,40,2.4,c),_s(11,34,39,22,2.2,hi)]
		"work": return [_rr(28,36,13,6,1,c),_rr(28,26,9,5,1,hi),_rr(28,18,5,4,1,c)]
		# The Research board's inputs (inquiry_board.gd): a young people's
		# sprout, and learning running ahead of the calendar.
		"sprout": return [_s(28,44,28,24,2.6,c),_t(28,26,14,17,22,30,hi),_t(28,22,42,13,34,27,hi),_s(12,45,44,45,1.8,dim)]
		"ahead": return [_s(10,40,46,40,1.8,dim),_s(12,31,36,31,3.2,c),_t(46,31,34,22,34,40,hi),_s(14,22,14,40,1.6,dim),_s(20,25,20,40,1.6,dim)]
		# The troubles a year is remembered by (chronicle_annals.gd glyph_of).
		# A hard sun over cracked ground.
		"drought":
			var sun:Array=[_c(28,19,6.5,hi)]
			for i in 8:
				var a:=TAU*float(i)/8.0
				sun.append(_s(28+cos(a)*9.5,19+sin(a)*9.5,28+cos(a)*12.5,19+sin(a)*12.5,1.8,c))
			sun.append_array([_s(9,39,47,39,2.4,dim),_s(19,39,22,44,1.4,dim),_s(22,44,20,48,1.2,dim),_s(35,39,32,44,1.4,dim),_s(32,44,35,48,1.2,dim)])
			return sun
		# A hut roof above the water, and the waves.
		"flood": return [_t(28,12,17,24,39,24,hi),_rr(28,28,8,4,1,c),
			_s(9,35,15,31,2.2,hi),_s(15,31,21,35,2.2,hi),_s(21,35,27,31,2.2,hi),_s(27,31,33,35,2.2,hi),_s(33,35,39,31,2.2,hi),_s(39,31,45,35,2.2,hi),
			_s(12,43,18,39,2.0,c),_s(18,39,24,43,2.0,c),_s(24,43,30,39,2.0,c),_s(30,39,36,43,2.0,c),_s(36,43,42,39,2.0,c)]
		# Flames over a hut, and their smoke.
		"fire": return [_rr(28,40,13,4,1,dim),_t(23,11,14,36,32,36,hi),_t(34,17,27,36,41,36,c),_t(24,21,19,36,29,36,Color(1,0.92,0.62,0.95)),
			_c(38,10,3.2,Color(0.62,0.60,0.56,0.8)),_c(42,6,2.2,Color(0.62,0.60,0.56,0.6))]
		# One laid down, and the heat over them.
		"sickness": return [_s(9,41,47,41,1.6,dim),_c(15,34,4,hi),_rr(30,35,11,3.8,3,c),_s(24,26,24,21,1.6,hi),_s(30,24,30,18,1.6,hi),_s(36,26,36,21,1.6,hi)]
		# One laid down, and the stranger who brought it.
		"stranger": return [_s(9,41,47,41,1.6,dim),_c(13,35,3.6,hi),_rr(25,36,9,3.4,3,c),_c(41,19,3.4,dim.lightened(0.25)),_rr(41,29,3.6,7,2.5,dim.lightened(0.25)),_s(30,26,35,22,1.4,hi)]
		# The sun veiled, and frost beneath.
		"cold": return [_c(28,20,9,Color(hi,0.8)),_s(12,17,44,17,2.2,Color(0.035,0.066,0.060,0.9)),_s(12,23,44,23,2.2,Color(0.035,0.066,0.060,0.9)),
			_s(28,33,28,47,1.5,c),_s(22,36,34,44,1.5,c),_s(34,36,22,44,1.5,c)]
		# An empty bowl.
		"hunger": return [_c(28,28,13,c),_rr(28,21,15,7.5,0,Color(0.035,0.066,0.060,1)),_s(14,28,42,28,2.4,hi),_c(28,33,4,Color(0.035,0.066,0.060,0.9)),_rr(28,43,6,1.6,1,dim)]
		# A dead tree on worn ground.
		"thinning": return [_s(9,42,47,42,2.2,dim),_rr(28,37,2.4,5,1,c),_s(28,33,28,15,1.8,c),_s(28,27,20,19,1.6,c),_s(28,23,36,15,1.6,c),_s(20,19,17,20,1.2,c),_s(28,31,35,27,1.4,c)]
		# The world view (hud/world_globe.gd): a ring of the world with its
		# graticule, the side meridians bowed in short strokes.
		"world": return [_ring(28,28,15,2.4,hi),_s(13.5,28,42.5,28,1.6,c),_s(16,20,40,20,1.2,c),_s(16,36,40,36,1.2,c),_s(28,13,28,43,1.6,c),
			_s(28,13,21.5,19,1.3,c),_s(21.5,19,20,28,1.3,c),_s(20,28,21.5,37,1.3,c),_s(21.5,37,28,43,1.3,c),
			_s(28,13,34.5,19,1.3,c),_s(34.5,19,36,28,1.3,c),_s(36,28,34.5,37,1.3,c),_s(34.5,37,28,43,1.3,c)]
	# Founding and anything unnamed: the hearth fire.
	return [_t(28,11,18,36,38,36,hi),_t(28,21,23,36,33,36,Color(1,0.92,0.62,0.95)),_s(16,40,40,44,2.4,dim),_s(40,40,16,44,2.4,dim)]


# -- War on the map ---------------------------------------------------------

static var _war_textures:Dictionary={}

## The few marks an early war leaves on the map, drawn so each reads without
## a legend: "band" is a few figures with spears, "raid" is fire and smoke at
## the place that was struck, "feud" is two crossed spears.
static func war_texture(kind:String,accent:Color,px:int=ICON_PX)->Texture2D:
	var key:="%s|%s|%d" % [kind,accent.to_html(),px]
	if _war_textures.has(key): return _war_textures[key]
	var texture:=ImageTexture.create_from_image(_render(_war_glyph(kind,accent),px))
	_war_textures[key]=texture
	return texture


static func _war_glyph(kind:String,c:Color)->Array:
	var hi:=c.lightened(0.30)
	match kind:
		"band":
			var out:Array=[]
			for x in [17.0,28.0,39.0]:
				var y:=3.0 if x==28.0 else 0.0
				out.append_array([
					_c(x,19-y,3.4,c),_rr(x,30-y,3.6,7.5,2.6,c),
					_s(x-1.6,37-y,x-2.4,44-y,2.2,c),_s(x+1.6,37-y,x+2.4,44-y,2.2,c),
					_s(x+5,11-y,x+5,44-y,1.4,hi),_t(x+5,6-y,x+3,12-y,x+7,12-y,hi),
				])
			return out
		"raid":
			var smoke:=Color(0.62,0.60,0.56,0.85)
			return [
				_c(23,20,6,smoke),_c(31,14,5,smoke),_c(36,9,3.5,Color(smoke,0.6)),
				_t(28,24,18,44,38,44,Color("#d8612f")),_t(28,31,22,44,34,44,Color("#f2b544")),
				_s(15,45,41,45,2.2,Color("#5a4632")),
			]
		"feud":
			return [_s(14,42,40,14,2.6,c),_s(42,42,16,14,2.6,c),_t(40,14,44,10,36,12,hi),_t(16,14,12,10,20,12,hi)]
	return [_c(28,28,8,c)]


# -- Forces on the war chart ------------------------------------------------

static var _army_textures:Dictionary={}

## Inked marks for forces on the war chart (see hud/army_marks.gd), drawn
## bare with a paper halo so they read over any ground:
##   "band:N"    a tally of N spears bound together (N 2..5);
##   "host"      a leader's standard: pole, crossbar and a streamer;
##   "army"      a framed standard with the arm's symbol on its cloth;
##   "colours"   the gunpowder age's standard: a square flag flying from a
##               pike, the arm's symbol on it;
##   "formation" a staff-map box with the branch symbol.
## branch: foot, horse, missile, guns, engineers, motor, armour, autonomous
## (drones, robots and combat frames: a lattice). ink draws the strokes;
## accent (the owner's colour) touches only the streamer, the tally's tie or
## a wash on the cloth.
static func army_texture(kind:String,branch:String,ink:Color,accent:Color,px:int=64)->Texture2D:
	var key:="%s|%s|%s|%s|%d" % [kind,branch,ink.to_html(),accent.to_html(),px]
	if _army_textures.has(key): return _army_textures[key]
	var texture:=ImageTexture.create_from_image(_render_boxed(_with_halo(army_glyph(kind,branch,ink,accent),Color(0.94,0.89,0.76,0.92),2.4),px))
	_army_textures[key]=texture
	return texture


## The glyph's primitives on the 56 px grid.
static func army_glyph(kind:String,branch:String,ink:Color,accent:Color)->Array:
	var paper:=Color(0.95,0.91,0.80,1.0)
	var wash:=Color(accent,0.5)
	if kind.begins_with("band"):
		var count:=clampi(int(kind.get_slice(":",1)) if ":" in kind else 3,2,5)
		var out:Array=[]
		var spread:=7.0
		var left:=28.0-spread*float(count-1)*0.5
		for k in count:
			var x:=left+spread*float(k)
			var lean:=(float(k)-float(count-1)*0.5)*1.2
			out.append_array([_s(x-lean,50,x+lean,15,2.4,ink),_t(x+lean,5,x+lean-3.2,15,x+lean+3.2,15,ink)])
		# The binding: one tally stroke across the spears, with the owner's tie.
		out.append(_s(left-5,42,left+spread*float(count-1)+5,34,2.6,ink))
		out.append(_c(28,38,2.6,accent))
		return out
	match kind:
		"host":
			return [
				_s(24,53,24,9,2.8,ink),_c(24,6,3.2,ink),_s(14,13,36,13,2.4,ink),
				_t(25,14,25,34,50,21,ink),_t(26.5,16.5,26.5,30.5,45,21.5,accent),
				_s(15,13,14,21,1.6,ink),_s(35,13,36,21,1.6,ink),_s(17,53,31,53,2.6,ink),
			]
		"army":
			var cloth:=[_s(28,55,28,8,2.8,ink),_t(28,1,24.5,8,31.5,8,ink),_s(12,10,44,10,2.6,ink),
				_rr(28,25,14,13,1.0,ink),_rr(28,25,11.6,10.6,0.6,paper),_rr(28,25,11.6,10.6,0.6,wash)]
			for x in [18.0,23.0,28.0,33.0,38.0]: cloth.append(_s(x,39,x,42,1.4,ink))
			cloth.append_array(_arm_symbol(branch,28,25,8.5,ink))
			return cloth
		"colours":
			var flag:=[_s(18,55,18,7,2.8,ink),_t(18,0.5,15,8,21,8,ink),_c(18,9.5,2.0,ink),
				_rr(33,22,14,12,0.8,ink),_rr(33,22,11.8,9.8,0.5,paper),_rr(33,22,11.8,9.8,0.5,wash),
				_s(19,10,14,24,1.3,ink),_c(13.6,25.5,1.9,ink),_s(12,55,24,55,2.6,ink)]
			flag.append_array(_arm_symbol(branch,33,22,7.5,ink))
			return flag
		"formation":
			var box:=[_rr(28,31,21,14,0.6,ink),_rr(28,31,18.8,11.8,0.3,paper),_rr(28,31,18.8,11.8,0.3,wash)]
			box.append_array(_branch_symbol(branch,28,31,18.8,11.8,ink,paper))
			return box
	return [_c(28,28,6,ink)]


## The arm's symbol on a standard's cloth (older, drawn signs).
static func _arm_symbol(branch:String,x:float,y:float,r:float,ink:Color)->Array:
	match branch:
		"horse": return [_s(x-r,y+r*0.7,x+r,y-r*0.7,2.2,ink),_c(x+r*0.65,y-r*0.55,2.4,ink)]
		"missile":
			var bow:=[Vector2(x-1,y-r),Vector2(x-r*0.55,y-r*0.55),Vector2(x-r*0.75,y),Vector2(x-r*0.55,y+r*0.55),Vector2(x-1,y+r)]
			var out:=[_s(x-1,y-r,x-1,y+r,1.2,ink),_s(x-r*0.7,y,x+r*0.8,y,1.8,ink),_t(x+r+1,y,x+r*0.8-2,y-2.6,x+r*0.8-2,y+2.6,ink)]
			for k in range(1,bow.size()): out.append(_s(bow[k-1].x,bow[k-1].y,bow[k].x,bow[k].y,2.0,ink))
			return out
		"guns","engineers": return [_ring(x,y,r*0.62,2.0,ink),_c(x,y,1.8,ink)]
		"armour": return [_rr(x,y,r*0.9,r*0.5,r*0.5,ink),_rr(x,y,r*0.9-1.8,r*0.5-1.8,r*0.5-1.8,Color(0.95,0.91,0.80,1.0))]
		"autonomous": return lattice(x,y,r*0.9,r*0.8,1.6,ink)
	return [_s(x-r,y+r*0.8,x+r,y-r*0.8,2.2,ink),_s(x-r,y-r*0.8,x+r,y+r*0.8,2.2,ink)]


## The staff-map branch symbols inside a box of half-size (hw, hh).
static func _branch_symbol(branch:String,x:float,y:float,hw:float,hh:float,ink:Color,paper:Color)->Array:
	var diagonal_a:=_s(x-hw,y+hh,x+hw,y-hh,2.0,ink)
	var diagonal_b:=_s(x-hw,y-hh,x+hw,y+hh,2.0,ink)
	match branch:
		"horse": return [diagonal_a]
		"guns": return [_c(x,y,3.8,ink)]
		"armour": return [_rr(x,y,hw*0.62,hh*0.5,hh*0.5,ink),_rr(x,y,hw*0.62-2.0,hh*0.5-2.0,hh*0.5-2.0,paper)]
		"motor": return [diagonal_a,diagonal_b,_c(x-hw*0.5,y+hh+4.5,2.2,ink),_c(x+hw*0.5,y+hh+4.5,2.2,ink)]
		"engineers": return [_s(x-hw*0.55,y-hh*0.45,x+hw*0.55,y-hh*0.45,2.0,ink),_s(x-hw*0.55,y-hh*0.45,x-hw*0.55,y+hh*0.4,2.0,ink),_s(x+hw*0.55,y-hh*0.45,x+hw*0.55,y+hh*0.4,2.0,ink),_s(x,y-hh*0.45,x,y+hh*0.4,2.0,ink)]
		"missile": return [diagonal_a,diagonal_b,_c(x,y-hh*0.55,1.8,ink)]
		"autonomous": return lattice(x,y,hw*0.62,hh*0.74,1.7,ink)
	return [diagonal_a,diagonal_b]


## The autonomous sign: a lattice (a diamond cut into four by its midlines,
## a node at each crossing), for drones, robots and combat frames.
static func lattice(x:float,y:float,rx:float,ry:float,w:float,ink:Color)->Array:
	var top:=Vector2(x,y-ry); var right:=Vector2(x+rx,y); var bottom:=Vector2(x,y+ry); var left:=Vector2(x-rx,y)
	var out:Array=[]
	for edge in [[top,right],[right,bottom],[bottom,left],[left,top],[(top+left)*0.5,(right+bottom)*0.5],[(top+right)*0.5,(left+bottom)*0.5]]:
		out.append(_s(edge[0].x,edge[0].y,edge[1].x,edge[1].y,w,ink))
	for node in [top,right,bottom,left,Vector2(x,y)]: out.append(_c(node.x,node.y,w*1.15,ink))
	return out


## A paper halo beneath a glyph: each primitive again, grown, in paper.
static func _with_halo(primitives:Array,paper:Color,grow:float)->Array:
	var out:Array=[]
	for primitive_variant in primitives:
		var primitive:Dictionary=(primitive_variant as Dictionary).duplicate()
		primitive.col=paper
		primitive["g"]=grow
		out.append(primitive)
	out.append_array(primitives)
	return out


## The same distance fields and compositing as _render (without the disc),
## but each primitive is evaluated only inside its own bounds, in order, so
## a glyph with many strokes and a halo stays cheap to bake.
static func _render_boxed(primitives:Array,px:int=ICON_PX)->Image:
	var scale:=float(px)/float(ICON_PX)
	var pixels:=PackedColorArray()
	pixels.resize(px*px)
	pixels.fill(Color(0,0,0,0))
	for primitive_variant in primitives:
		var primitive:Dictionary=primitive_variant
		var col:Color=primitive.col
		if col.a<=0.0: continue
		var grow:=float(primitive.get("g",0.0))
		var box:=_bounds(primitive).grow(grow+1.5)
		var x0:=clampi(floori(box.position.x*scale),0,px-1); var x1:=clampi(ceili(box.end.x*scale),0,px-1)
		var y0:=clampi(floori(box.position.y*scale),0,px-1); var y1:=clampi(ceili(box.end.y*scale),0,px-1)
		for y in range(y0,y1+1):
			for x in range(x0,x1+1):
				var coverage:=clampf(0.5-(_sd(primitive,Vector2(x+0.5,y+0.5)/scale)-grow)*scale,0.0,1.0)*col.a
				if coverage<=0.0: continue
				var i:=y*px+x
				var out:Color=pixels[i]
				out.r=lerpf(out.r,col.r,coverage); out.g=lerpf(out.g,col.g,coverage); out.b=lerpf(out.b,col.b,coverage)
				out.a=out.a+(1.0-out.a)*coverage
				pixels[i]=out
	var image:=Image.create(px,px,false,Image.FORMAT_RGBA8)
	for y in px:
		for x in px: image.set_pixel(x,y,pixels[y*px+x])
	image.generate_mipmaps()
	return image


static func _bounds(primitive:Dictionary)->Rect2:
	var a:Vector2=primitive.a
	match int(primitive.k):
		0,5: return Rect2(a,Vector2.ZERO).grow(float(primitive.r))
		1: return Rect2(a,Vector2.ZERO).grow(float(primitive.r)+float(primitive.w)*0.5)
		2,6: return Rect2(a,Vector2.ZERO).expand(primitive.b).grow(float(primitive.r))
		3: return Rect2(a,Vector2.ZERO).expand(primitive.b).expand(primitive.c)
		4: return Rect2(a-(primitive.b as Vector2),(primitive.b as Vector2)*2.0)
		7:
			var box:=Rect2(a,Vector2.ZERO)
			for point in (primitive.pts as PackedVector2Array): box=box.expand(point)
			return box
	return Rect2(0,0,ICON_PX,ICON_PX)



# -- The People -------------------------------------------------------------

static var _people_textures:Dictionary={}

## Marks for the People screen: the six vitals (fed, stores, water, shelter,
## life, spirit) drawn on the disc, and small standing figures for what the
## people are doing (gather, hunt, fish, tend, build, fetch, make, carry,
## scout, learn, steward, watch), drawn bare so a row of them reads as a crowd.
static func people_texture(kind:String,accent:Color,px:int=ICON_PX,disc:bool=true)->Texture2D:
	var key:="%s|%s|%d|%s" % [kind,accent.to_html(),px,disc]
	if _people_textures.has(key): return _people_textures[key]
	var texture:=ImageTexture.create_from_image(_render(_people_glyph(kind,accent),px,disc))
	_people_textures[key]=texture
	return texture


static func _figure(x:float,c:Color)->Array:
	## One standing person, feet on the 48 line.
	return [_c(x,13,5.2,c),_rr(x,27,6,9.5,4,c),_s(x-2.6,36,x-3.6,48,3.4,c),_s(x+2.6,36,x+3.6,48,3.4,c)]


static func _people_glyph(kind:String,c:Color)->Array:
	var hi:=c.lightened(0.32)
	var dim:=c.darkened(0.35)
	var dark:=Color(0.035,0.066,0.060,1)
	match kind:
		# Vitals, on the disc.
		"fed": return [_rr(28,34,15,7,6,c),_rr(28,27,17,2.2,1,hi),_c(22,24,3.6,hi),_c(29,23,4,hi),_c(35,24.5,3.4,hi),_s(24,17,25,11,1.4,dim),_s(32,17,31,11,1.4,dim)]
		"stores": return _pot(c,hi)+[_s(19,31,37,31,1.4,dark),_s(19,37,37,37,1.4,dark)]
		"water": return _droplet(c,hi)
		"shelter": return [_t(28,9,9,31,47,31,c),_rr(28,38,13,8,1,hi),_rr(28,41,3.6,5.5,1,dark),_s(28,9,28,5,1.6,dim)]
		"life": return [_c(24,14,5,c),_rr(24,28,6,9.5,4,c),_s(21.5,37,20.5,48,3.2,c),_s(26.5,37,27.5,48,3.2,c),_s(35,12,33,48,2.2,hi),_c(35,12,2.4,hi)]
		"spirit": return [_c(19,16,4.2,c),_rr(19,29,5,9,3,c),_c(37,16,4.2,c),_rr(37,29,5,9,3,c),_s(23,26,33,26,2.4,hi),_t(28,32,24,44,32,44,Color(1,0.72,0.35,0.95)),_t(28,37,26,44,30,44,Color(1,0.92,0.62,0.95))]
		# Figures at work, bare.
		"gather": return [_c(20,16,5,c),_s(21,21,29,34,8,c),_s(27,35,24,48,3.2,c),_s(30,35,33,48,3.2,c),_s(24,26,36,34,2.6,c),_rr(41,40,7,6,2.5,hi),_s(34,34,48,34,1.6,hi)]
		"hunt": return _figure(24,c)+[_s(41,6,35,50,2.2,hi),_t(41,3,38,11,44,11,hi),_s(24,24,38,22,2.6,c)]
		"fish": return _figure(22,c)+[_s(26,24,38,20,2.4,c),_s(38,20,51,8,1.6,hi),_s(51,8,51,30,1,hi),_c(51,34,3.2,hi),_t(47,34,44,31,44,37,hi)]
		"tend": return _figure(20,c)+[_s(24,26,36,36,2.4,c),_s(42,49,42,34,2.2,hi),_c(38,33,3.6,hi),_c(46,31,3.6,hi),_c(42,27,3.2,hi)]
		"build": return _figure(20,c)+[_s(24,24,34,18,2.4,c),_s(34,48,42,28,2.4,hi),_s(42,28,50,48,2.4,hi),_s(37,40,47,40,1.8,hi)]
		"fetch": return _figure(26,c)+[_s(8,19,48,15,4.4,hi),_c(8,19,2.4,dim),_c(48,15,2.4,dim)]
		"make": return [_c(20,20,5,c),_rr(20,33,6,8,4,c),_s(16,41,30,44,3.4,c),_s(24,30,36,28,2.4,c),_s(36,28,44,20,2.2,hi),_rr(45,19,4,2.6,1,hi),_rr(40,44,8,3,1,dim)]
		"carry": return _figure(24,c)+[_rr(34,24,6.5,9,3,hi),_s(30,18,34,15,1.6,hi)]
		"scout": return [_c(24,13,5,c),_rr(25,27,5.5,9,4,c),_s(22,36,16,47,3.3,c),_s(28,36,33,47,3.3,c),_s(28,24,38,28,2.4,c),_s(39,10,41,49,2,hi)]
		"learn": return _figure(20,c)+[_rr(39,27,8,10,1,hi),_s(34,22,44,22,1.2,dark),_s(34,26,44,26,1.2,dark),_s(34,30,42,30,1.2,dark),_s(24,26,32,28,2.4,c)]
		"steward": return _figure(24,c)+[_s(38,12,38,49,2,hi),_ring(38,10,3.6,1.6,hi),_s(24,24,37,22,2.4,c)]
		"watch": return _figure(26,c)+[_s(39,4,39,50,2,hi),_t(39,1,36,8,42,8,hi),_rr(18,28,4,7,2,dim)]
	return _figure(28,c)


# -- Scout chart marks --------------------------------------------------------

static var _chart_textures:Dictionary={}

## Small inked marks for the scout chart, drawn bare on a faint paper wash so
## they read over any ground: a camp tent, a find (four-point star), a
## sighting (an eye), and the walker figure for a party still out.
static func chart_texture(kind:String,ink:Color,px:int=40)->Texture2D:
	var key:="%s|%s|%d" % [kind,ink.to_html(),px]
	if _chart_textures.has(key): return _chart_textures[key]
	var texture:=ImageTexture.create_from_image(_render(_chart_glyph(kind,ink),px,false))
	_chart_textures[key]=texture
	return texture


static func _chart_glyph(kind:String,c:Color)->Array:
	var paper:=Color(0.95,0.90,0.78,0.62)
	var wash:=_c(28,28,17,Color(paper,0.40))
	match kind:
		"camp": return [wash,_t(28,15,15,39,41,39,c),_t(28,26,24,39,32,39,paper),_s(12,40,44,40,2.2,c)]
		"find": return [wash,_t(28,10,24.5,28,31.5,28,c),_t(28,46,24.5,28,31.5,28,c),_t(10,28,28,24.5,28,31.5,c),_t(46,28,28,24.5,28,31.5,c),_c(28,28,3.2,paper)]
		"sighting": return [wash,_ring(28,28,11,2.6,c),_c(28,28,4.6,c),_s(28,11,28,6,2.2,c),_s(40,16,43,12,2.2,c),_s(16,16,13,12,2.2,c)]
		"walker": return [_c(28,30,19,paper),_ring(28,30,19,1.8,Color(c,0.7))]+_figure_small(28,c)+[_s(36,14,38,46,2.2,c)]
	return [wash,_c(28,28,5,c)]


static func _figure_small(x:float,c:Color)->Array:
	return [_c(x,17,4.2,c),_rr(x,28,4.6,7.2,3,c),_s(x-1.8,35,x-4.5,45,3.0,c),_s(x+1.8,35,x+4.0,45,3.0,c)]


# -- Settlement marks on the chart ---------------------------------------------

const SETTLEMENT_GLYPH_PX:=64
## Glyph cells in `settlement_atlas()`: settlement stages 0-6 (camp to
## megalopolis), then a stranger's reported town, a stranger's town we hold,
## a rival people's chief town, a town under siege, and a burned or ruined one.
const SETTLEMENT_GLYPH_FOREIGN:=7
const SETTLEMENT_GLYPH_OCCUPIED:=8
const SETTLEMENT_GLYPH_RIVAL_CAPITAL:=9
const SETTLEMENT_GLYPH_BESIEGED:=10
const SETTLEMENT_GLYPH_RUINED:=11
const SETTLEMENT_GLYPH_COUNT:=12
static var _settlement_atlas:Texture2D

## Chart marks for places, as an engraver sets them: a small ringed dot for a
## camp, heavier rings as a place grows, a walled ring with towers for a city,
## outer rings for the great cities, and an open diamond for a stranger's town
## known only by report. Iron-gall ink on a paper disc, so every mark reads
## over dark ground and pale vellum alike. One strip, one texture.
static func settlement_atlas()->Texture2D:
	if _settlement_atlas!=null: return _settlement_atlas
	var cell:=SETTLEMENT_GLYPH_PX
	var strip:=Image.create(cell*SETTLEMENT_GLYPH_COUNT,cell,false,Image.FORMAT_RGBA8)
	for index in SETTLEMENT_GLYPH_COUNT:
		var glyph:=_render(_settlement_glyph(index),cell,false)
		glyph.clear_mipmaps()
		strip.blit_rect(glyph,Rect2i(0,0,cell,cell),Vector2i(index*cell,0))
	strip.generate_mipmaps()
	_settlement_atlas=ImageTexture.create_from_image(strip)
	return _settlement_atlas


## How far a settlement glyph reaches from its centre, as a fraction of its
## cell (the halo radius on the 56px grid), for marks drawn around it.
static func settlement_glyph_extent(index:int)->float:
	return float([14.0,16.0,18.0,20.0,22.0,24.4,27.1,22.0,26.0,24.0,27.0,22.0][clampi(index,0,SETTLEMENT_GLYPH_COUNT-1)])/float(ICON_PX)

static func _settlement_glyph(index:int)->Array:
	var ink:=Color("#2b2118")
	var paper:=Color("#f1e7cf")
	var halo:=Color(0.95,0.91,0.82,0.55)
	match index:
		0: return [_c(28,28,14,halo),_c(28,28,11.5,paper),_ring(28,28,10.5,2.6,ink),_c(28,28,3.4,ink)]
		1: return [_c(28,28,16,halo),_c(28,28,13.5,paper),_ring(28,28,12.5,2.8,ink),_c(28,28,4.4,ink)]
		2: return [_c(28,28,18,halo),_c(28,28,15.5,paper),_ring(28,28,14.5,3.0,ink),_c(28,28,6.5,ink)]
		3: return [_c(28,28,20,halo),_c(28,28,17.5,paper),_ring(28,28,16.5,3.2,ink),_ring(28,28,9.8,2.2,ink),_c(28,28,4.2,ink)]
		SETTLEMENT_GLYPH_FOREIGN:
			return [_d(28,28,22,halo),_d(28,28,19,paper)]+_ring_diamond(28,28,17,2.8,ink)+[_c(28,28,3.6,ink)]
		SETTLEMENT_GLYPH_OCCUPIED:
			# Their town inside our gold band: taken and held, not yet our own.
			return [_c(28,28,26,halo),_c(28,28,24,paper),_ring(28,28,21.5,5.2,Color("#a88a4a")),_ring(28,28,24.4,1.1,ink),_ring(28,28,18.6,0.9,ink)]+_ring_diamond(28,28,14,2.6,ink)+[_c(28,28,3.4,ink)]
		SETTLEMENT_GLYPH_RIVAL_CAPITAL:
			# A people's chief town: the stranger's diamond doubled, its heart filled.
			return [_d(28,28,24,halo),_d(28,28,21.5,paper)]+_ring_diamond(28,28,19.5,2.6,ink)+_ring_diamond(28,28,12,2.2,ink)+[_d(28,28,5.5,ink)]
		SETTLEMENT_GLYPH_BESIEGED:
			# Siege lines drawn round the town in oxblood.
			var siege:Array=[_c(28,28,27,halo),_d(28,28,17,paper)]+_ring_diamond(28,28,15,2.6,ink)+[_c(28,28,3.2,ink)]
			for tick in 12:
				var a:=TAU*float(tick)/12.0+PI/12.0
				siege.append(_s(28+cos(a)*20.0,28+sin(a)*20.0,28+cos(a)*25.0,28+sin(a)*25.0,2.4,Color("#8e3b2e")))
			return siege
		SETTLEMENT_GLYPH_RUINED:
			# A burned town: the stranger's diamond in faded ink, its wall broken
			# in two places, a heap of rubble, and one small flame. No crossed or
			# turning strokes: a ruin must never read as any sign or emblem.
			var faded:=Color("#6b5e4e")
			var fire:=Color("#8e3b2e")
			return [_d(28,28,22,halo),_d(28,28,19,Color(paper,0.8)),
				_s(28,11,34,17,2.6,faded),_s(40,23,45,28,2.6,faded),_s(45,28,28,45,2.6,faded),
				_s(28,45,22,39,2.6,faded),_s(16,33,11,28,2.6,faded),_s(11,28,28,11,2.6,faded),
				_rr(22,36,3.2,2.2,0.8,faded),_rr(28.5,37,3.6,2.4,0.8,faded),_rr(34.5,35.5,2.6,2.0,0.8,faded),
				_t(28,15,23.2,28,32.8,28,fire),_c(28,28,4.8,fire)]
	# Cities: a walled ring with towers, then outer rings for greater cities.
	var parts:Array=[_c(28,28,22,halo),_c(28,28,19,paper)]
	for tower in 8:
		var angle:=TAU*float(tower)/8.0
		parts.append(_rr(28+cos(angle)*18.0,28+sin(angle)*18.0,3.0,3.0,0.7,ink))
	parts.append_array([_ring(28,28,17,3.2,ink),_c(28,28,8,ink),_c(28,28,3,paper)])
	if index>=5: parts.append(_ring(28,28,23.5,1.7,ink))
	if index>=6: parts.append(_ring(28,28,26.4,1.3,ink))
	return parts


static func _ring_diamond(x:float,y:float,r:float,w:float,col:Color)->Array:
	var top:=Vector2(x,y-r); var right:=Vector2(x+r,y); var bottom:=Vector2(x,y+r); var left:=Vector2(x-r,y)
	return [_s(top.x,top.y,right.x,right.y,w,col),_s(right.x,right.y,bottom.x,bottom.y,w,col),_s(bottom.x,bottom.y,left.x,left.y,w,col),_s(left.x,left.y,top.x,top.y,w,col)]


# -- Peoples' emblems -------------------------------------------------------------

static var _emblem_textures:Dictionary={}

## Outlines a stranger people's emblem can take. The round seal is kept for
## our own people alone, so ours never reads as anyone else's.
const EMBLEM_SHAPES:=["shield","lozenge","banner","arch","cushion","pennon","quatrefoil","cartouche"]
const EMBLEM_SIGIL_COUNT:=12
const EMBLEM_INK:=Color("#2b2118")
const EMBLEM_PAPER:=Color("#f1e7cf")
const EMBLEM_GOLD:=Color("#c9a14e")

## A people's emblem, drawn once and cached: their outline (`shape`), their
## sign (`sigil`, 0-11) in `ink` on a `field` of their colour, inside a band
## of `accent`, with an iron-gall keyline and a paper halo so it reads over
## any ground at card size. `shape` "seal" is our own people's mark: a round
## seal of ink with a gold band, gold sign and a gold star above.
static func emblem_texture(shape:String,sigil:int,field:Color,accent:Color,ink:Color,px:int=96)->Texture2D:
	var key:="%s|%d|%s|%s|%s|%d" % [shape,sigil,field.to_html(),accent.to_html(),ink.to_html(),px]
	if _emblem_textures.has(key):return _emblem_textures[key]
	var texture:=ImageTexture.create_from_image(_render_boxed(emblem_glyph(shape,sigil,field,accent,ink),px))
	if _emblem_textures.size()>=160:_emblem_textures.clear()
	_emblem_textures[key]=texture
	return texture


## The emblem's primitives on the 56 px grid (see emblem_texture).
static func emblem_glyph(shape:String,sigil:int,field:Color,accent:Color,ink:Color)->Array:
	var outline:=_emblem_outline(shape)
	var parts:Array=[]
	parts.append_array(_grown(outline,2.6,Color(EMBLEM_PAPER,0.9)))
	parts.append_array(_grown(outline,0.0,EMBLEM_INK))
	parts.append_array(_grown(outline,-1.7,accent))
	parts.append_array(_grown(outline,-4.0,field))
	var centre:=_emblem_centre(shape)
	parts.append_array(_sigil(posmod(sigil,EMBLEM_SIGIL_COUNT),centre.x,centre.y,_emblem_sigil_scale(shape),ink,field))
	if shape=="seal":
		# The home star, set on the band at the top of the seal.
		parts.append_array(_star(28,6.5,6.2,Color(EMBLEM_PAPER,0.95),1.4))
		parts.append_array(_star(28,6.5,6.2,EMBLEM_GOLD,0.0))
	return parts


## One outline as primitives, filling most of the 56 px cell.
static func _emblem_outline(shape:String)->Array:
	var c:=Color.WHITE
	match shape:
		"seal": return [_c(28,30,23,c)]
		"shield": return [_rr(28,17,19,10,3,c),_t(9,20,47,20,28,53,c),_c(18,26,9,c),_c(38,26,9,c)]
		"lozenge": return [_d(28,28,26,c)]
		"banner": return [_rr(28,22,18,16,1.5,c),_t(10,30,28,30,10,53,c),_t(28,30,46,30,46,53,c),_rr(28,34,18,4,0,c)]
		"arch": return [_rr(28,36,19,15,2,c),_c(28,24,19,c)]
		"cushion": return [_rr(28,28,22,22,9,c)]
		"pennon": return [_t(4,6,52,6,28,54,c),_rr(28,9,22,4,2,c)]
		"quatrefoil": return [_c(28,15,11.5,c),_c(28,41,11.5,c),_c(15,28,11.5,c),_c(41,28,11.5,c),_c(28,28,13,c)]
		"cartouche": return [_rr(28,28,17,25,14,c)]
	return [_c(28,28,23,c)]


## Where the sign sits inside each outline, and how large.
static func _emblem_centre(shape:String)->Vector2:
	match shape:
		"shield": return Vector2(28,25)
		"banner": return Vector2(28,24)
		"pennon": return Vector2(28,20)
		"arch": return Vector2(28,32)
		"seal": return Vector2(28,31)
	return Vector2(28,28)

static func _emblem_sigil_scale(shape:String)->float:
	match shape:
		"pennon": return 0.72
		"lozenge": return 0.82
		"shield","banner": return 0.86
	return 1.0


## Primitives recoloured and grown (negative: inset) as a whole.
static func _grown(primitives:Array,grow:float,col:Color)->Array:
	var out:Array=[]
	for primitive_variant in primitives:
		var primitive:Dictionary=(primitive_variant as Dictionary).duplicate()
		primitive.col=col
		primitive["g"]=grow
		out.append(primitive)
	return out


## A five-pointed star of radius r, as five blades round a hub.
static func _star(x:float,y:float,r:float,col:Color,grow:float)->Array:
	var out:Array=[]
	var inner:=r*0.42
	for k in 5:
		var a:=-PI*0.5+TAU*float(k)/5.0
		var tip:=Vector2(x,y)+Vector2(cos(a),sin(a))*r
		var left:=Vector2(x,y)+Vector2(cos(a-PI/5.0),sin(a-PI/5.0))*inner
		var right:=Vector2(x,y)+Vector2(cos(a+PI/5.0),sin(a+PI/5.0))*inner
		var blade:=_t(tip.x,tip.y,left.x,left.y,right.x,right.y,col);blade["g"]=grow;out.append(blade)
	var hub:=_c(x,y,inner,col);hub["g"]=grow;out.append(hub)
	return out


## Twelve signs, one per people's lineage: tree, sun, waves, peaks, star,
## crescent, crossed spears, tower, birds, eye, fish, key. Drawn in `c` at
## (x, y); `ground` paints what a sign cuts away (the crescent's shadow).
static func _sigil(index:int,x:float,y:float,k:float,c:Color,ground:Color)->Array:
	var w:=3.0*k
	match index:
		0: return [_s(x,y+11*k,x,y+2*k,w,c),_t(x,y-12*k,x-9*k,y+4*k,x+9*k,y+4*k,c)]
		1:
			var sun:Array=[_c(x,y,5.5*k,c)]
			for r in 8:
				var a:=TAU*float(r)/8.0
				sun.append(_s(x+cos(a)*8.5*k,y+sin(a)*8.5*k,x+cos(a)*12*k,y+sin(a)*12*k,2.2*k,c))
			return sun
		2:
			var waves:Array=[]
			for row:float in [-5.0,5.0]:
				for seg in 4:
					var x0:=x-12*k+6*k*float(seg)
					var up:=-3.0*k if seg%2==0 else 3.0*k
					waves.append(_s(x0,y+row*k+up*0.5,x0+6*k,y+row*k-up*0.5,2.4*k,c))
			return waves
		3: return [_t(x-4*k,y-10*k,x-14*k,y+9*k,x+6*k,y+9*k,c),_t(x+6*k,y-5*k,x-2*k,y+9*k,x+14*k,y+9*k,c)]
		4: return [_t(x,y-13*k,x-3.5*k,y,x+3.5*k,y,c),_t(x,y+13*k,x-3.5*k,y,x+3.5*k,y,c),_t(x-13*k,y,x,y-3.5*k,x,y+3.5*k,c),_t(x+13*k,y,x,y-3.5*k,x,y+3.5*k,c)]
		5: return [_c(x,y,11*k,c),_c(x+5.5*k,y-3*k,9.5*k,ground)]
		6: return [_s(x-10*k,y+11*k,x+9*k,y-8*k,w,c),_s(x+10*k,y+11*k,x-9*k,y-8*k,w,c),_t(x+12*k,y-12*k,x+6*k,y-10*k,x+10*k,y-6*k,c),_t(x-12*k,y-12*k,x-6*k,y-10*k,x-10*k,y-6*k,c)]
		7: return [_rr(x,y+3*k,6.5*k,9*k,0.5,c),_rr(x-5*k,y-8*k,1.8*k,2.5*k,0.3,c),_rr(x,y-8*k,1.8*k,2.5*k,0.3,c),_rr(x+5*k,y-8*k,1.8*k,2.5*k,0.3,c),_rr(x,y+8*k,2*k,3.5*k,1.5*k,ground)]
		8: return [_s(x-12*k,y-4*k,x-5*k,y+1*k,w,c),_s(x-5*k,y+1*k,x+2*k,y-4*k,w,c),_s(x-2*k,y+4*k,x+5*k,y+9*k,w,c),_s(x+5*k,y+9*k,x+12*k,y+4*k,w,c)]
		9: return [_s(x-13*k,y,x,y-8*k,2.4*k,c),_s(x,y-8*k,x+13*k,y,2.4*k,c),_s(x-13*k,y,x,y+8*k,2.4*k,c),_s(x,y+8*k,x+13*k,y,2.4*k,c),_c(x,y,4.2*k,c)]
		10: return [_rr(x-2*k,y,9*k,5.5*k,5*k,c),_t(x+6*k,y,x+13*k,y-7*k,x+13*k,y+7*k,c),_c(x-6*k,y-1.5*k,1.4*k,ground)]
		11: return [_ring(x,y-6*k,5*k,2.6*k,c),_s(x,y-1*k,x,y+13*k,w,c),_s(x,y+8*k,x+5*k,y+8*k,2.4*k,c),_s(x,y+12*k,x+4*k,y+12*k,2.4*k,c)]
	return [_c(x,y,5*k,c)]


# -- Great works on the chart --------------------------------------------------

static var _great_work_textures:Dictionary={}

## A great work's chart emblem: its form (tower, colossus, hall, ring...) inked
## on a small square paper plaque, set apart from the round settlement marks.
## The plaque's edge tells the state: solid ink when standing, a gold outer
## rule once dedicated, a broken edge with the upper part ghosted while it
## rises, and a cracked, faded mark for a ruin. Drawn bare (no disc).
static func great_work_texture(shape:String,state:String="standing",px:int=48)->Texture2D:
	var key:="%s|%s|%d" % [shape,state,px]
	if _great_work_textures.has(key): return _great_work_textures[key]
	var texture:=ImageTexture.create_from_image(_render(great_work_glyph(shape,state),px,false))
	_great_work_textures[key]=texture
	return texture


static func great_work_glyph(shape:String,state:String="standing")->Array:
	var ink:=Color("#2b2118")
	var paper:=Color("#f1e7cf")
	var gold:=Color("#a88a4a")
	var faded:=Color("#7a6f60")
	var halo:=Color(0.95,0.91,0.82,0.55)
	var ruined:=state=="ruined"
	var unfinished:=state in ["building","abandoned"]
	var c:=faded if ruined or state=="abandoned" else ink
	var parts:Array=[_rr(28,28,21,21,6,halo)]
	if state=="dedicated": parts.append_array([_rr(28,28,20.5,20.5,5,gold),_rr(28,28,18.8,18.8,4.5,paper)])
	if unfinished:
		# A broken edge: the plaque is still being laid out.
		parts.append(_rr(28,28,17,17,4,paper))
		for side in 4:
			for half:float in [-1.0,1.0]:
				var along:=half*9.0
				var a:Vector2;var b:Vector2
				match side:
					0: a=Vector2(28+along-5,11.8);b=Vector2(28+along+5,11.8)
					1: a=Vector2(28+along-5,44.2);b=Vector2(28+along+5,44.2)
					2: a=Vector2(11.8,28+along-5);b=Vector2(11.8,28+along+5)
					_: a=Vector2(44.2,28+along-5);b=Vector2(44.2,28+along+5)
				parts.append(_s(a.x,a.y,b.x,b.y,2.2,c))
	else:
		parts.append_array([_rr(28,28,17,17,4,c),_rr(28,28,15.2,15.2,3,paper)])
	parts.append_array(_great_work_form(shape,c,paper))
	if unfinished:
		# The upper courses are not built yet: ghost them.
		parts.append(_rr(28,20,14.4,7.5,0,Color(paper,0.66)))
	if ruined:
		parts.append_array([_s(18,15,38,42,2.6,paper),_c(19,40.5,1.6,c),_c(37.5,40.5,1.3,c)])
	return parts


static func _great_work_form(shape:String,c:Color,paper:Color)->Array:
	match shape:
		"tower": return [_rr(28,40,8,2,1,c),_rr(28,28,4.2,11,0.8,c),_rr(28,17,6,1.5,0.5,c),_t(28,9,22.5,15.5,33.5,15.5,c)]
		"lighthouse": return [_rr(28,40,8,2,1,c),_t(28,18,23,38,33,38,c),_rr(28,16,4.5,1.5,0.5,c),_c(28,12,3,c),_s(20,11,17,9,1.6,c),_s(36,11,39,9,1.6,c)]
		"colossus": return [_rr(28,40.5,9,2,1,c),_c(28,13,3.2,c),_rr(28,22.5,4.5,6,2,c),_s(26,28,24.5,37,3,c),_s(30,28,31.5,37,3,c),_s(32,18.5,37,11,2.4,c),_s(24,18.5,22,26,2.4,c)]
		"ring":
			var stones:Array=[]
			for i in 8:
				var a:=TAU*float(i)/8.0
				stones.append(_rr(28+cos(a)*10.5,28+sin(a)*10.5,2.2,2.2,0.6,c))
			stones.append(_c(28,28,2.2,c))
			return stones
		"mound","terrace": return [_rr(28,39,13,2.6,0.5,c),_rr(28,33.2,9.8,2.6,0.5,c),_rr(28,27.4,6.6,2.6,0.5,c),_rr(28,21.6,3.4,2.6,0.5,c)]
		"basin": return [_rr(28,29,12.5,9,2,c),_rr(28,29,9.8,6.4,1.5,paper),_s(20.5,29.5,24,27.5,1.6,c),_s(24,27.5,28,30.5,1.6,c),_s(28,30.5,32,27.5,1.6,c),_s(32,27.5,35.5,29.5,1.6,c)]
		"orchard": return [_c(19,23,5,c),_c(28,20,5.5,c),_c(37,23,5,c),_s(19,27,19,37,2.2,c),_s(28,25,28,37,2.2,c),_s(37,27,37,37,2.2,c),_s(14,38,42,38,2,c)]
		"kilns": return [_c(19,35,6,c),_c(28,32,7,c),_c(37,35,6,c),_rr(28,40.5,14,2.5,0,paper),_s(14,38,42,38,2,c),_c(28,20,2,c),_c(30,15,1.5,c)]
		"bridge": return [_s(13,23,43,23,3,c),_ring(20.5,33,7,3,c),_ring(35.5,33,7,3,c),_rr(28,39.8,14.4,3.8,0,paper),_s(15,41,41,41,1.6,c)]
		"dam": return [_rr(31,28,3.5,12,0.5,c),_t(34,16,34,40,41,40,c),_s(15,21,25,21,1.6,c),_s(15,27,25,27,1.6,c),_s(15,33,25,33,1.6,c)]
		"canal": return [_s(14,20,42,20,2.4,c),_s(14,36,42,36,2.4,c),_s(16,28,21,26,1.6,c),_s(21,26,26,30,1.6,c),_s(26,30,31,26,1.6,c),_s(31,26,36,30,1.6,c),_s(36,30,40,28,1.6,c)]
		"causeway": return [_rr(28,26,14,2.6,1,c),_rr(18,32,1.4,4,0.4,c),_rr(25,32,1.4,4,0.4,c),_rr(31,32,1.4,4,0.4,c),_rr(38,32,1.4,4,0.4,c),_s(15,39,24,39,1.5,c),_s(30,39,41,39,1.5,c)]
		"gate": return [_rr(20,30,4,10.5,0.5,c),_rr(36,30,4,10.5,0.5,c),_rr(28,17.5,13,3,0.5,c),_ring(28,29,5.2,2.4,c),_rr(28,34.5,4,5.5,0,paper)]
		"observatory": return [_rr(28,40,13,2.4,0.5,c),_rr(28,35,9.5,2.4,0.5,c),_c(28,27.5,7,c),_rr(28,33.2,7.5,1,0,c),_s(27,25,34,19,1.8,paper)]
		"amphitheatre": return [_ring(28,37,13.5,2.4,c),_ring(28,37,9,2.4,c),_ring(28,37,4.6,2.2,c),_rr(28,41.4,14.4,3.6,0,paper),_s(15,38.6,41,38.6,2,c)]
		"granary": return [_s(20,33,20,40,2,c),_s(36,33,36,40,2,c),_rr(28,29,11,5,0.5,c),_t(28,13,13.5,25,42.5,25,c),_s(15,40.5,41,40.5,1.8,c)]
	# A hall, archive or house: a long roof over a pillared front.
	return [_t(28,13,13,25,43,25,c),_rr(28,32,11.5,6,0.5,c),_rr(28,34.5,2.5,3.5,0.5,paper),_s(14,39.5,42,39.5,2.2,c)]


# -- Arms (battle view block plates) ------------------------------------------

static var _arm_textures:Dictionary={}

## A block, a production line or a roster card, drawn as its weapon, mount or
## machine, inked on a paper halo (hud/battle_panel.gd plates, the Production
## screen, roster insignia). Every land kit's ledger glyph
## (equipment_ledger.gd "glyph") has its own mark, from the club to the
## combat frame; the battle rules' coarse arms (guns, armour, engineers)
## keep theirs. accent (the side's colour) touches one small detail only: a
## sash, a pennon, a shield boss, a sensor's glow.
static func arm_texture(arm:String,ink:Color,accent:Color,px:int=48)->Texture2D:
	var key:="%s|%s|%s|%d" % [arm,ink.to_html(),accent.to_html(),px]
	if _arm_textures.has(key): return _arm_textures[key]
	var texture:=ImageTexture.create_from_image(_render_boxed(_with_halo(arm_glyph(arm,ink,accent),Color(0.95,0.91,0.80,0.9),1.6),px))
	_arm_textures[key]=texture
	return texture


## Every mark arm_glyph draws: the ledger's glyphs and the coarse arms.
const ARM_GLYPHS:=["club","spear","pike","sword","axe","bow","sling","javelin","horse_archer","crossbow",
	"horse","chariot","elephant","heavy_horse","dragoon","hand_cannon","musket","rifle","mountain","marine",
	"engineer","assault_rifle","paratrooper","helicopter","networked","exosuit","machine_gun","mortar",
	"anti_tank","anti_air","laser","ram","catapult","trebuchet","bombard","field_gun","howitzer","rocket",
	"precision","lorry","armored_car","light_tank","tank","heavy_tank","tank_destroyer","carrier","mbt",
	"drone","robot_vehicle","combat_frame","support","guns","armour","engineers"]


static func arm_glyph(arm:String,ink:Color,accent:Color)->Array:
	var paper:=Color(0.95,0.91,0.80,1.0)
	match arm:
		# Hand arms and missiles, the first ages.
		"club": return [_s(15,46,33,20,3.4,ink),_c(35,16,7,ink),_c(29,22,4,ink),_s(13,48,19,42,2.0,accent)]
		"spear": return [_s(11,47,37,17,2.6,ink),_t(45,8,33,15,40,22,ink),_s(16,42,21,47,2.2,accent)]
		"pike": return [_s(7,51,43,11,2.2,ink),_t(49,5,40,10,45,15,ink),_s(7,11,43,51,2.2,ink),_t(49,55,40,50,45,45,ink),_c(25,31,2.6,accent)]
		"sword": return [_s(28,10,28,37,3.4,ink),_t(28,4,24.6,11,31.4,11,ink),_s(19,38,37,38,3.2,ink),_s(28,39,28,48,3.6,ink),_c(28,51,3.0,accent)]
		"axe": return [_s(17,50,33,11,2.8,ink),_t(29,9,46,7,43,27,ink),_t(29,9,43,27,33,21,ink),_s(15,52,20,46,2.0,accent)]
		"bow":
			var arc:=[Vector2(20,6),Vector2(30,12),Vector2(35,28),Vector2(30,44),Vector2(20,50)]
			var out:=[_s(20,6,20,50,1.2,ink),_s(12,28,44,28,2.0,ink),_t(50,28,43,24.5,43,31.5,ink),_s(12,28,8,24,1.6,accent),_s(12,28,8,32,1.6,accent)]
			for k in range(1,arc.size()): out.append(_s(arc[k-1].x,arc[k-1].y,arc[k].x,arc[k].y,2.8,ink))
			return out
		"sling": return [_s(14,10,25,31,1.8,ink),_s(35,10,25,31,1.8,ink),_c(25,34,4.6,ink),_c(42,42,4.2,ink),_s(31,47,37,44,1.4,accent),_s(29,42,35,40,1.4,accent)]
		"javelin": return [_s(9,43,38,14,2.2,ink),_t(44,8,35,12,40,17,ink),_s(16,51,45,22,2.2,ink),_t(51,16,42,20,47,25,ink),_c(24,40,2.2,accent)]
		# A crossbow from above: the stock, the bent prod, the drawn string, a bolt.
		"crossbow":
			var prod:=[Vector2(7,27),Vector2(15,18),Vector2(28,14),Vector2(41,18),Vector2(49,27)]
			var crossbow:=[_s(28,12,28,52,3.6,ink),_t(28,4,24.6,12,31.4,12,ink),_s(7,27,28,33,1.2,ink),_s(49,27,28,33,1.2,ink),_rr(28,40,3.4,2.4,0.8,ink),_s(28,43,33,48,1.8,ink),_c(28,23,2.0,accent)]
			for k in range(1,prod.size()): crossbow.append(_s(prod[k-1].x,prod[k-1].y,prod[k].x,prod[k].y,3.0,ink))
			return crossbow
		# A ship's fighter: round shield with a boss, a boat hook, the waves.
		"marine":
			var sea:Array=[_s(12,42,41,9,2.4,ink),_s(41,9,45,4,2.0,ink),_s(41,9,46,11,2.0,ink),_s(46,11,45,15,1.8,ink),
				_c(24,29,10,ink),_ring(24,29,7,1.3,paper),_c(24,29,2.6,accent)]
			for k in 8:
				var x:=5.0+float(k)*6.0
				sea.append(_s(x,47.0 if k%2==0 else 43.0,x+6.0,43.0 if k%2==0 else 47.0,2.2,ink))
			return sea
		# Mounts.
		"horse": return battle_figure_glyph("horse",ink,accent)
		"chariot": return [_ring(19,40,9,2.4,ink),_s(19,31,19,49,1.4,ink),_s(10,40,28,40,1.4,ink),_rr(32,30,10,7,1.5,ink),_s(41,33,53,41,2.2,ink),_c(32,17,3.6,ink),_s(32,20,32,25,2.8,ink),_s(29,22,36,24,1.6,accent)]
		# An elephant with its driver on the neck and a tower on its back.
		"elephant": return [_rr(28,32,15,10,9,ink),_c(44,26,8,ink),_s(50,30,52,48,3.2,ink),_s(19,38,19,51,4.4,ink),_s(33,38,33,51,4.4,ink),_s(45,34,49,38,1.6,paper),_c(46.5,23.5,1.0,paper),
			_rr(24,19,7,4.5,1,ink),_s(17,14,17,19,1.6,ink),_s(24,14,24,19,1.6,ink),_s(31,14,31,19,1.6,ink),_c(40,15,2.8,ink),_rr(40,20,2.4,3,1.2,ink),_s(17.5,22,30.5,22,1.3,accent)]
		# A rider at the gallop, a short recurved bow drawn forward.
		"horse_archer":
			var archer:Array=[_rr(27,35,13,5.5,5,ink),_s(38,33,45,23,4.0,ink),_rr(46,22,4.5,2.6,1.5,ink),
				_s(35,39,45,46,2.4,ink),_s(33,39,40,51,2.4,ink),_s(19,39,9,45,2.4,ink),_s(22,39,15,51,2.4,ink),_s(15,33,7,37,1.8,ink),
				_c(26,11,3.8,ink),_rr(26,21,4.2,6.5,2.6,ink),_s(26,26,30,33,2.6,ink),_s(28,17,39,15,2.2,ink),
				_s(35,3,28,15,0.9,ink),_s(35,27,28,15,0.9,ink),_s(28,15,46,15,1.2,ink),_t(49,15,45,13,45,17,ink),_s(23,19,31,24,1.8,accent)]
			var limb:=[Vector2(35,3),Vector2(39,6),Vector2(41,15),Vector2(39,24),Vector2(35,27)]
			for k in range(1,limb.size()): archer.append(_s(limb[k-1].x,limb[k-1].y,limb[k].x,limb[k].y,2.4,ink))
			return archer
		# A big horse in a trapper to the knees, a helmed rider, the lance
		# couched level with a pennon.
		"heavy_horse": return [_rr(27,34,14,6.5,5,ink),_poly([11,30,43,30,45,42,42,46,39,42,35,46,31,42,27,46,23,42,19,46,15,42,11,46,9,42],ink),_s(12,37,42,37,1.0,paper),
			_s(16,45,16,52,2.8,ink),_s(22,45,22,52,2.8,ink),_s(34,45,35,52,2.8,ink),_s(40,45,41,52,2.8,ink),
			_s(40,32,47,21,4.6,ink),_rr(48,20,4.8,2.8,1.5,ink),_s(11,33,6,41,2.0,ink),
			_c(25,12,3.4,ink),_t(25,4,21.4,11,28.6,11,ink),_rr(25,22,4.6,6.2,2.2,ink),_s(8,26,55,19,2.2,ink),_t(49,19.8,41,17,41.5,22.5,accent)]
		# A rider in a long coat and cocked hat, firing his carbine from the saddle.
		"dragoon": return [_rr(27,35,13,5.5,5,ink),_s(38,33,45,22,4.0,ink),_rr(46,21,4.5,2.6,1.5,ink),_s(17,39,15,52,2.4,ink),_s(21,39,21,52,2.4,ink),
			_s(33,39,34,52,2.4,ink),_s(37,39,39,52,2.4,ink),_s(15,33,9,40,1.8,ink),
			_c(27,12.5,3.4,ink),_ob(19,9.6,35,9.6,1.8,ink),_rr(27,7.4,4,2.4,1.5,ink),_rr(27,21,4.2,6,2.6,ink),_poly([22,24,32,24,34,33,20,32],ink),
			_poly([25,15,30,14,31,20,26,21],ink),_ob(28,16,47,12,2.2,ink),_s(29,18,38,17,2.2,ink),_c(51,10,3.0,Color(ink,0.45)),_c(55,7,2.0,Color(ink,0.3)),_s(24,19,31,24,1.8,accent)]
		# Firearms.
		# A bronze tube on a pole, the match glowing at the touch-hole.
		"hand_cannon": return [_s(6,51,25,31,2.6,ink),_ob(23,33,41,15,6.4,ink),_ob(39.5,16.5,43.5,12.5,8.2,ink),_c(26,25,2.2,accent),
			_c(47,8,3.2,Color(ink,0.45)),_c(52,4.5,2.2,Color(ink,0.3))]
		"musket": return [_s(11,45,48,12,2.4,ink),_t(6,52,18,43,11,38,ink),_c(22,36,2.6,ink),_s(24,39,26,43,1.6,accent)]
		"rifle": return [_s(11,45,45,15,2.2,ink),_s(45,15,52,8,1.4,ink),_t(6,52,17,43,11,38,ink),_rr(27,33,2.2,3.4,0.6,ink),_s(17,38,32,26,1.2,accent)]
		# A rifle across the peaks.
		"mountain": return [_poly([2,50,19,17,28,31,36,21,54,50],ink),_poly([19,17,15,25,19,23,23,25],paper),_poly([36,21,33,26,36,25,39,27],paper),
			_s(9,47,48,12,5.6,paper),_s(11,45,45,15,2.2,ink),_s(45,15,52,8,1.4,ink),_t(6,52,17,43,11,38,ink),_rr(27,33,2.2,3.4,0.6,ink),_s(19,17,19,7,1.2,ink),_t(19.5,7,19.5,12,25,9.5,accent)]
		# A short automatic from the side: pistol grip and a curved magazine.
		"assault_rifle": return [_poly([4,23,17,21,17,29,6,34],ink),_rr(25,24,9,3.6,1.2,ink),_ob(33,23,52,23,2.2,ink),_ob(33,20,43,20,1.8,ink),
			_s(46,23,46,18.5,1.8,ink),_s(21,27,18,36,3.4,ink),_s(29,27,30.5,35,4.2,ink),_s(30.5,35,35,41,4.2,ink),_s(8,31,27,31,1.1,accent)]
		# A soldier under a canopy.
		"paratrooper":
			var canopy:Array=[28,24]
			for k in 13:
				var a:=PI+PI*float(k)/12.0
				canopy.append_array([28.0+18.0*cos(a),24.0+14.0*sin(a)])
			return [_poly(canopy,ink),_s(28,11,19,24,1.0,paper),_s(28,11,37,24,1.0,paper),_c(28,11.5,1.8,accent),
				_s(10,24,26.5,40,1.1,ink),_s(46,24,29.5,40,1.1,ink),_s(19,24,27,40,1.0,ink),_s(37,24,29,40,1.0,ink),
				_c(28,40,3.0,ink),_rr(28,46,3,4,1.6,ink),_s(27,49.5,25.5,54,2.0,ink),_s(29,49.5,30.5,54,2.0,ink)]
		# A transport helicopter: the rotor bar over the cabin.
		"helicopter": return [_s(3,11,53,11,2.2,ink),_rr(25,11,3.2,1.8,0.8,ink),_s(25,11,25,20,2.6,ink),_rr(25,27,13,7,6.5,ink),_rr(34,24.5,4,3,1.8,paper),
			_s(36,25,51,21,3.0,ink),_s(51,21,53,14,2.4,ink),_ring(52,19,3.6,1.2,ink),
			_s(12,41,38,41,2.2,ink),_s(38,41,41,38.5,2.0,ink),_s(18,33,17,41,1.6,ink),_s(32,33,33,41,1.6,ink),_s(41,23.4,47,22.2,1.2,accent)]
		# A helmeted head and shoulders with a night optic and a radio mast;
		# the data link's tick in the side's colour.
		"networked": return [_s(24,33,20,51,3.6,ink),_s(28,33,33,51,3.6,ink),_rr(26,26,5.5,8.5,3,ink),_rr(27,24,6.8,6,1.5,ink),_rr(27,24,4.6,1,0.4,paper),
			_c(28,13.5,4.4,ink),_rr(27,10.5,6.2,3.8,3.6,ink),_ob(31.5,8.5,35.5,11.5,1.6,ink),_rr(37,13.5,2.8,1.8,0.8,ink),
			_s(22,21,17,4,1.2,ink),_s(29,20,38,21,2.6,ink),_ob(22,19,49,19,2.4,ink),_s(37,20,38,26,2.6,ink),_s(46,19,46,15.5,1.6,ink),
			_s(9,6,12,9,1.7,accent),_s(12,9,17,2,1.7,accent)]
		# A soldier inside a frame: battery spine, thick jointed limbs, a
		# heavy weapon carried in one arm.
		"exosuit": return [_rr(19,21,3,10,1.2,ink),_s(17,24,21,24,0.9,paper),_s(17,28,21,28,0.9,paper),_rr(19,15,1.2,1.8,0.4,accent),
			_c(30,9,4.4,ink),_s(32,9,34.5,9,1.2,paper),_rr(28,15.5,5.5,1.8,0.8,ink),_poly([21,16,35,16,33,31,24,31],ink),
			_s(32,18,37,25,4.4,ink),_ob(31,28,53,26,4.0,ink),_rr(38,31.5,3,2.6,0.6,ink),_rr(28,33,5.5,2.4,1,ink),
			_s(26,34,22,41,4.6,ink),_s(22,41,21,49,4.2,ink),_rr(23,50.5,4.2,1.6,0.6,ink),
			_s(31,34,34,41,4.8,ink),_s(34,41,32,49,4.4,ink),_rr(34,50.5,4.4,1.6,0.6,ink),_c(34,41,1.2,paper),_c(22,41,1.1,paper)]
		# Crew weapons.
		"machine_gun": return [_s(12,22,48,22,3.2,ink),_rr(19,22,7,5.5,1.2,ink),_s(22,27,13,46,2.2,ink),_s(22,27,31,46,2.2,ink),_s(22,27,22,46,2.2,ink),_s(16,29,10,38,1.8,accent)]
		# A short fat tube on a base plate, a bomb in the air.
		"mortar": return [_rr(16,48,9,2.2,1,ink),_ob(16,46,31,16,5.6,ink),_ob(30,18,32,14,7.0,ink),_s(26,26,36,48,2.2,ink),_s(26,26,30,48,1.8,ink),_s(31,37,35,37,1.4,ink),
			_s(43,13,47,7,4.2,ink),_t(41,15,38.5,15.5,41.5,12.5,ink),_s(44,12,46,9,1.2,accent)]
		# A low gun behind a shield, its barrel long and thin.
		"anti_tank": return [_poly([18,20,23.5,20,28.5,40,23,40],ink),_ob(18,30,53,30,2.2,ink),_rr(53,30,1.8,2.6,0.4,ink),_rr(27,32,6,2.4,1,ink),
			_c(23,43,5.6,ink),_c(23,43,2.0,paper),_s(21,39,4,48,2.8,ink),_s(22,24,25,24,1.2,accent)]
		# A quick-firing gun pointed at the sky on a cross mount.
		"anti_air": return [_s(8,49,48,43,2.6,ink),_s(8,43,48,49,2.6,ink),_rr(28,42,5,4,1.2,ink),_c(28,36,4.6,ink),_ob(28,36,39,5,3.0,ink),_ob(37.6,9,40.4,1,4.4,ink),
			_poly([20,33,26,31,26,40,20,40],ink),_ring(35,20,4.2,1.1,ink),_s(21,36,24,36,1.2,accent)]
		# A turret on a truck with a glass eye, and its beam.
		"laser": return [_rr(26,42,21,2.4,0.8,ink),_rr(46,37,5,5,1.2,ink),_rr(48,35,2.4,2,0.5,paper),_c(14,46,4.2,ink),_c(14,46,1.5,paper),_c(38,46,4.2,ink),_c(38,46,1.5,paper),
			_rr(22,34,10,5,2,ink),_c(26,27,6.4,ink),_ring(26,27,4.0,1.3,paper),_c(26,27,2.2,accent),_s(31,23,55,4,1.2,ink),_s(51,4,55,8,1.0,ink),_s(51,8,55,4,1.0,ink)]
		# Siege engines and guns.
		# A tree trunk on ropes under a hide roof, on rollers.
		"ram": return [_t(28,9,4,28,52,28,ink),_s(8,23,48,23,1.0,paper),_s(10,28,10,42,2.6,ink),_s(46,28,46,42,2.6,ink),_ob(3,36,52,36,5.2,ink),_rr(52.5,36,2.8,4,1,ink),
			_s(22,28,22,33,1.2,ink),_s(34,28,34,33,1.2,ink),_ring(16,46,4,2,ink),_ring(40,46,4,2,ink),_t(28,9,28,2,35,5.5,accent)]
		# A torsion engine: a throwing arm and cup on a low timber frame.
		"catapult": return [_ob(5,45,51,45,3.6,ink),_rr(8,46,2.4,3.4,0.6,ink),_rr(48,46,2.4,3.4,0.6,ink),_c(17,41,4.2,ink),_c(17,41,1.6,paper),
			_s(17,41,38,11,2.8,ink),_c(39.5,9,3.6,ink),_s(34,45,31,25,2.6,ink),_s(42,45,37,25,2.6,ink),_rr(34,24,6,2.2,1,ink),_s(24,45,34,34,1.6,ink),_c(39.5,9,1.3,accent)]
		# A tall frame, a long arm with its sling, a box of stones for a counterweight.
		"trebuchet": return [_s(5,51,51,51,2.6,ink),_s(14,51,27,18,2.6,ink),_s(40,51,29,18,2.6,ink),_s(18,41,37,41,1.8,ink),_c(28,18,2.4,ink),
			_s(28,18,6,5,2.4,ink),_s(28,18,38,24,3.0,ink),_s(38,24,38,28,1.6,ink),_rr(38,33,6.5,5.5,1,ink),_s(32,33,44,33,1.2,accent),
			_s(6,5,4,14,1.0,ink),_c(4,15.5,2.2,ink)]
		# A huge banded tube raised on a timber bed, stakes behind to take the kick.
		"bombard":
			var bombard:Array=[_rr(27,45.5,21,2.6,0.8,ink),_s(5,35,3,49,2.4,ink),_s(9,37,8,49,2.0,ink),_t(32,43,46,43,46,33,ink),
				_ob(8,38.5,18,36,8.4,ink),_ob(16,36.5,44,29.5,12.6,ink),_ob(43,29.75,47,28.75,15.4,ink)]
			var along:=Vector2(28,-7).normalized(); var across:=along.orthogonal()
			for t in [9.0,17.0,25.0]:
				var mid:=Vector2(16,36.5)+along*float(t)
				bombard.append(_s(mid.x-across.x*5.6,mid.y-across.y*5.6,mid.x+across.x*5.6,mid.y+across.y*5.6,1.1,paper))
			bombard.append(_c(12,33,1.5,accent))
			return bombard
		# A cast gun on a two-wheeled carriage: the big spoked wheel and the trail.
		"field_gun":
			var gun:Array=[_s(22,36,4,50,3.8,ink),_s(20,33,50,23,4.6,ink),_c(51,22.6,2.8,ink),_c(17,34,2.4,ink)]
			for k in 6:
				var a:=TAU*float(k)/6.0+0.3
				gun.append(_s(25,39,25+cos(a)*9.5,39+sin(a)*9.5,1.4,ink))
			gun.append_array([_ring(25,39,10,2.6,ink),_c(25,39,2.4,ink),_c(17,34,1.2,accent)])
			return gun
		# A steel howitzer: recoil cylinder under the barrel, tyred wheel, split trail.
		"howitzer": return [_s(24,39,2,47,2.6,ink),_s(24,39,14,52,2.6,ink),_ob(21,34,52,16,3.4,ink),_ob(50.5,17,54.5,14.6,5.2,ink),_ob(22,38,38,28.5,2.6,ink),
			_poly([28,25,34,22,35,36,29,38],ink),_c(26,43,7,ink),_ring(26,43,3.4,1.3,paper),_s(30,26,33,24.5,1.2,accent)]
		# A rack of rails on a lorry.
		"rocket":
			var rack:Array=[_rr(25,40,22,2.4,0.8,ink),_poly([40,40,40,30,46,30,51,35,51,40],ink),_rr(45,33,1.8,1.6,0.4,paper),
				_c(12,45,4.2,ink),_c(12,45,1.5,paper),_c(24,45,4.2,ink),_c(24,45,1.5,paper),_c(44,45,4.2,ink),_c(44,45,1.5,paper),
				_s(22,38,28,27,2.4,ink),_s(34,38,31,27,2.0,ink)]
			for k in 4:
				var o:=float(k)*3.2
				rack.append(_ob(6+o*0.45,34-o,40+o*0.45,18-o,1.7,ink))
			rack.append(_t(46,14,41,15.5,42.5,11.5,ink))
			rack.append(_s(7,32,12,29.6,1.2,accent))
			return rack
		# A boxy launcher pod raised on a wheeled lorry.
		"precision": return [_rr(25,41,22,2.4,0.8,ink),_rr(45,34,6,6,1,ink),_rr(47,32,2.4,2,0.4,paper),
			_c(11,46,4,ink),_c(11,46,1.4,paper),_c(22,46,4,ink),_c(22,46,1.4,paper),_c(43,46,4,ink),_c(43,46,1.4,paper),
			_ob(8,32,36,17,11,ink),_s(22,39,24,29,2.4,ink),_ob(33.5,18.3,34.8,20.8,1.2,paper),_ob(30,20.2,31.3,22.7,1.2,paper),
			_s(45,28,45,23,1.2,ink),_c(45,22,1.8,accent)]
		# Vehicles.
		# A canvas-topped lorry.
		"lorry": return [_rr(20,27,15,10,5,ink),_s(13,19,13,36,1.2,paper),_s(20,17.5,20,36,1.2,paper),_s(27,19,27,36,1.2,paper),
			_poly([38,39,38,24,45,24,50,32,51,39],ink),_rr(43.5,28,2.6,2.8,0.5,paper),_rr(27,39,24,2.6,0.8,ink),
			_c(14,44,5,ink),_c(14,44,1.8,paper),_c(43,44,5,ink),_c(43,44,1.8,paper),_s(6,34,10,34,1.2,accent)]
		# A four-wheeled steel box with a small turret.
		"armored_car": return [_poly([5,38,7,29,17,26,41,26,49,31,51,38],ink),_c(15,42,6.2,ink),_c(15,42,2.2,paper),_c(41,42,6.2,ink),_c(41,42,2.2,paper),
			_s(8,35.5,49,35.5,1.0,paper),_rr(28,21,6.5,4.5,3,ink),_ob(34,20.5,45,20.5,2.0,ink),_rr(40,30,2.4,1.6,0.4,paper),_s(24,19.5,30,19.5,1.2,accent)]
		# A small tank on a tall track frame, a tail skid behind.
		"light_tank": return [_poly([11,48,39,48,47,38,44,30,14,33,9,40],ink),_c(15,44,1.7,paper),_c(21,44.5,1.7,paper),_c(27,44.5,1.7,paper),_c(33,44.5,1.7,paper),_c(41,38,2.0,paper),
			_s(11,41,3,49,2.6,ink),_rr(27,26,6,5,2.5,ink),_rr(27,19.6,3,2,1,ink),_ob(32,25.5,41,25.5,2.2,ink),_s(23,24,27,24,1.2,accent)]
		# A medium tank: sloped front, round turret, a medium gun.
		"tank": return _tracks(28,42,21,5.5,6,ink,paper)+[_poly([7,38,11,31,39,31,50,38],ink),_rr(26,25,9,5.5,4.5,ink),_ob(34,24,51,23,2.6,ink),_s(20,23,27,23,1.4,accent)]
		# A heavy tank: slab sides, a box turret, a long gun with a muzzle brake.
		"heavy_tank": return _tracks(28,43,24,5,8,ink,paper)+[_rr(28,34,22,5,0.6,ink),_rr(26,24,11,5.5,1,ink),_ob(37,23.5,53,23.5,2.8,ink),_ob(51,23.5,55,23.5,4.6,ink),_s(19,21,25,21,1.4,accent)]
		# A tank destroyer: a low turretless casemate and a very long gun.
		"tank_destroyer": return _tracks(27,43,21,5,6,ink,paper)+[_poly([6,39,10,29,32,26,46,39],ink),_c(39,32,3,ink),_ob(39,32,56,27,2.4,ink),_s(14,30,20,29,1.4,accent)]
		# An armoured carrier: a tall tracked box with its ramp down behind.
		"carrier": return _tracks(30,44,18,4.5,5,ink,paper)+[_poly([13,41,13,21,36,21,48,34,48,41],ink),_ob(13,40,4,48,2.4,ink),
			_rr(18,31,2,6,0.5,paper),_s(28,21,28,16,1.6,ink),_ob(27,16,37,16,1.6,ink),_s(17,23.5,24,23.5,1.4,accent)]
		# A main battle tank: low hull and skirts, a flat wedge turret, a very long gun.
		"mbt": return [_rr(28,45,20,3,3,ink),_c(14,45,1.3,paper),_c(22,45,1.3,paper),_c(30,45,1.3,paper),_c(38,45,1.3,paper),_rr(28,39.5,21.5,3.2,0.5,ink),
			_poly([5,37,9,32,47,32,52,37],ink),_poly([13,31,14,25,31,24,42,28.5,40,31],ink),_ob(38,28,56,28,2.2,ink),_rr(21,22.8,2.6,1.6,0.4,ink),_s(24,26.5,30,26.5,1.2,accent)]
		# Drones and robots.
		# A four-rotor drone from above.
		"drone": return [_s(14,14,42,42,2.8,ink),_s(42,14,14,42,2.8,ink),_ring(14,14,7.5,2.2,ink),_ring(42,14,7.5,2.2,ink),_ring(14,42,7.5,2.2,ink),_ring(42,42,7.5,2.2,ink),
			_c(14,14,1.8,ink),_c(42,14,1.8,ink),_c(14,42,1.8,ink),_c(42,42,1.8,ink),_rr(28,28,5.5,5.5,1.8,ink),_c(28,28,2.2,accent)]
		# A driverless tracked machine: no hatch, a sensor mast, a remote gun.
		"robot_vehicle": return _tracks(26,44,20,4.5,5,ink,paper)+[_poly([7,40,10,34,40,34,46,40],ink),_rr(20,31,4.5,2.6,0.8,ink),_ob(24,31,35,31,1.6,ink),
			_s(38,34,38,16,2.0,ink),_rr(38,13,5,3.4,1.6,ink),_c(40.5,13,1.9,accent)]
		# A combat frame: a tall jointed machine, a shoulder yoke, one sensor
		# slit glowing where a face would be.
		"combat_frame": return [_rr(28,8,4,3.4,1,ink),_s(25.2,8,30.8,8,1.4,accent),_rr(28,13,1.8,2,0.4,ink),_rr(28,16,13.5,2.4,1,ink),
			_rr(14.5,19,4,5,1.4,ink),_rr(41.5,19,4,5,1.4,ink),_poly([21,17,35,17,32,30,24,30],ink),
			_s(14,24,13,35,3.0,ink),_s(42,24,43,35,3.0,ink),_ob(43,33,43,42,4.0,ink),_rr(28,31.5,6,2,1,ink),
			_s(25,32,18,40,4.2,ink),_s(18,40,23,49,3.6,ink),_s(20,51,29,51,2.6,ink),
			_s(32,32,26,40,4.4,ink),_s(26,40,34,49,3.8,ink),_s(32,51,42,51,2.8,ink),_c(18,40,2.6,ink),_c(26,40,2.8,ink)]
		# Engineers and the trains.
		"engineer","engineers": return [_s(14,47,40,15,2.4,ink),_rr(43,11,4.4,6,1.8,ink),_s(14,15,40,47,2.4,ink),_s(8,21,21,7,2.8,ink),_c(27,31,2.2,accent)]
		"support": return [_rr(28,25,15,9,1.5,ink),_ring(19,39,5.5,2.2,ink),_ring(37,39,5.5,2.2,ink),_s(43,24,53,18,2.2,ink),_s(28,19,28,31,2.4,paper),_s(22,25,34,25,2.4,paper)]
		# The battle rules' coarse arms: a gun, and armour as the medium tank.
		"guns": return [_s(15,34,47,18,5.6,ink),_ring(20,41,8,2.6,ink),_c(20,41,2.2,ink),_s(20,41,7,49,2.6,ink),_c(48,17,2.0,accent)]
		"armour": return arm_glyph("tank",ink,accent)
	return [_c(28,28,8,ink)]


## A tank's running gear: the track as a band of ink with paper road wheels.
static func _tracks(x:float,y:float,hw:float,hh:float,wheels:int,ink:Color,paper:Color)->Array:
	var out:Array=[_rr(x,y,hw,hh,hh,ink)]
	for k in wheels:
		var t:=float(k)/float(maxi(1,wheels-1))
		out.append(_c(lerpf(x-hw+hh,x+hw-hh,t),y,hh*0.42,paper))
	return out


# -- Battle figures ---------------------------------------------------------

## One fighter, inked, weapon by era and arm: "club", "spear", "bow",
## "sword" (sword and shield), "musket", "rifle", "horse" (a rider) and
## "fallen" (a fighter down). The owner's colour touches only a sash. The
## battle view's arm icons (arm_glyph) draw the rider from here.
static func battle_figure_glyph(kind:String,ink:Color,accent:Color)->Array:
	if kind=="fallen":
		return [_c(11,45,4.0,ink),_rr(24,45.5,9,3.6,2.4,ink),_s(33,45,47,47,3.0,ink),_s(33,46,45,50,2.6,ink),_s(6,51,44,51,1.4,ink),_s(20,43,28,45,1.8,accent)]
	if kind=="horse":
		return [_rr(27,35,13,5.5,5,ink),_s(38,33,45,22,4.0,ink),_rr(46,21,4.5,2.6,1.5,ink),_s(17,39,15,52,2.4,ink),_s(21,39,21,52,2.4,ink),
			_s(33,39,34,52,2.4,ink),_s(37,39,39,52,2.4,ink),_s(15,33,9,40,1.8,ink),
			_c(27,12,3.8,ink),_rr(27,22,4.2,6.5,2.6,ink),_s(27,27,31,34,2.6,ink),_s(24,19,32,24,1.8,accent),_s(31,19,46,3,1.6,ink)]
	var body:=[_c(28,10,4.6,ink),_rr(28,23,5.2,8.5,3.5,ink),_s(26,31,23.5,49,3.2,ink),_s(30,31,32.5,49,3.2,ink),_s(24,18,32,26,2.0,accent)]
	match kind:
		"club": body.append_array([_s(31,19,36,12,2.6,ink),_s(36,14,40,2,3.6,ink),_s(25,19,21,29,2.4,ink)])
		"bow": body.append_array([_s(31,19,40,19,2.4,ink),_s(25,19,31,20,2.2,ink),_s(40,6,43,19,1.7,ink),_s(43,19,40,32,1.7,ink),_s(40,6,40,32,0.9,ink)])
		"sword": body.append_array([_rr(21,24,5.5,8,2.5,ink),_rr(21,24,3.6,6,1.6,Color(0.95,0.91,0.80,1.0)),_s(32,21,40,11,2.0,ink),_s(30,21,34,23,2.4,ink)])
		"musket": body.append_array([_s(21,33,42,8,2.2,ink),_s(31,20,35,22,2.4,ink),_rr(28,5,6,1.4,0.6,ink)])
		"rifle": body.append_array([_s(22,32,40,12,2.0,ink),_s(31,20,34,22,2.4,ink),_rr(28,7,5.6,2.4,2.2,ink)])
		_: body.append_array([_s(31,19,35,26,2.6,ink),_s(36,2,36,52,1.8,ink),_t(36,-1,33.4,7,38.6,7,ink)])
	return body


# -- Army screens (HOI4-style rows) ----------------------------------------

static var _command_textures:Dictionary={}

## Small inked marks for the army screens (hud/army_bar.gd, the recruit
## queue and the army command panel), drawn bare so they sit beside a
## number the way a HOI4 row does. Kinds:
##   people    men, free (can be called up), serving, drilling, work (jobs
##             left undone at home), home
##   stores    gear (spear and shield), drill (rank chevrons), will (a
##             standard), supply (a grain sack), date (an hourglass)
##   orders    attack, besiege, raid, defend, guard, goto, recall, front
##             (a front line with its teeth), arrow (an offensive arrow)
##   controls  pause, resume, stop, repeat, deploy, edit, plus, minus,
##             prio0..prio2 (one to three chevrons)
## Unknown kinds draw a dot, never an error.
static func command_texture(kind:String,ink:Color,px:int=40)->Texture2D:
	var key:="%s|%s|%d" % [kind,ink.to_html(),px]
	if _command_textures.has(key): return _command_textures[key]
	var texture:=ImageTexture.create_from_image(_render(command_glyph(kind,ink),px,false))
	_command_textures[key]=texture
	return texture


static func command_glyph(kind:String,c:Color)->Array:
	var soft:=Color(c,0.5)
	match kind:
		"men": return [_c(37,14,5,soft),_rr(37,28,5.8,9,4,soft),_s(34.5,36,33.5,48,3.4,soft),_s(39.5,36,40.5,48,3.4,soft)]+_figure(23,c)
		"free": return _figure(22,c)+[_s(42,17,42,35,4,c),_s(33,26,51,26,4,c)]
		"serving": return _figure(22,c)+[_s(37,6,37,52,2.8,c),_t(37,1,33.2,10,40.8,10,c),_s(26,25,37,22,3,c)]
		"drilling": return _figure(20,c)+[_s(33,26,41,19,3.4,c),_s(41,19,49,26,3.4,c),_s(33,36,41,29,3.4,c),_s(41,29,49,36,3.4,c)]
		"work": return [_s(14,50,36,14,3.6,c),_t(33,9,49,15,40,24,c),_s(10,50,24,50,3,soft)]
		"home": return [_t(28,7,6,27,50,27,c),_rr(28,38,15,11,1,c)]
		"gear": return [_s(12,52,42,12,3.4,c),_t(48,4,38.4,11,44,15.2,c),_c(24,34,11.5,c)]
		"drill": return [_s(12,21,28,11,4.4,c),_s(28,11,44,21,4.4,c),_s(12,33,28,23,4.4,c),_s(28,23,44,33,4.4,c),_s(12,45,28,35,4.4,c),_s(28,35,44,45,4.4,c)]
		"will": return [_s(17,52,17,6,3.4,c),_t(18.5,8,18.5,30,47,19,c),_s(10,51,26,51,3.4,c)]
		"supply": return [_s(28,53,28,16,3.2,c),_c(28,11,4.6,c),_rr(21.5,21,4,6,4,c),_rr(34.5,21,4,6,4,c),_rr(21.5,32,4,6,4,c),_rr(34.5,32,4,6,4,c),_rr(21.5,43,4,6,4,soft),_rr(34.5,43,4,6,4,soft)]
		"date": return [_s(13,8,43,8,3.6,c),_s(13,48,43,48,3.6,c),_t(16,10,40,10,28,28,c),_t(16,46,40,46,28,28,soft)]
		"attack": return [_s(10,46,33,23,6,c),_t(47,9,28,15,41,28,c)]
		"besiege": return [_ring(28,28,11,4,c),_s(28,4,28,12,3.6,c),_s(28,44,28,52,3.6,c),_s(4,28,12,28,3.6,c),_s(44,28,52,28,3.6,c),_s(11,11,17,17,3.2,c),_s(45,11,39,17,3.2,c),_s(11,45,17,39,3.2,c),_s(45,45,39,39,3.2,c)]
		"raid": return [_t(28,3,17,40,39,40,c),_t(15,15,9,40,25,40,c),_t(42,12,31,40,47,40,c),_c(28,40,10,c),_s(8,52,48,52,3.2,soft)]
		"defend": return [_rr(28,16,16,8,1.2,c),_t(12,20,44,20,28,52,c)]
		"guard": return [_s(19,52,25,20,3.4,c),_s(37,52,31,20,3.4,c),_rr(28,18,11,3.4,1,c),_t(28,4,14,14,42,14,c),_s(21,42,35,32,2.6,c),_s(35,42,21,32,2.6,c)]
		"goto": return [_s(36,52,36,8,3.4,c),_t(37.5,9,37.5,27,53,18,c),_c(12,48,3.8,soft),_c(19,40,3.8,soft),_c(13,31,3.8,c)]
		# A storehouse under a pitched roof, stacked sacks beside it.
		"depot": return [_t(22,12,4,26,40,26,c),_rr(22,38,15,12,1,c),_rr(45,45,6,5,1.5,soft),_rr(45,34,5,4.5,1.5,soft),_s(4,52,54,52,2.4,soft)]
		"recall": return [_t(38,10,22,26,54,26,c),_rr(38,36,12,10,1,c),_s(4,40,17,40,4,c),_t(24,40,15,33,15,47,c)]
		"front": return [_s(4,34,52,34,4.4,c),_t(6,33,16,33,11,21,c),_t(19,33,29,33,24,21,c),_t(32,33,42,33,37,21,c),_t(45,33,53,33,49,22,c)]
		"arrow": return [_s(6,50,17,36,7,c),_s(17,36,29,27,6.4,c),_s(29,27,36,23.5,5.8,c),_t(52,15,32,14,40,33,c)]
		"pause": return [_rr(19,28,5,15,1.5,c),_rr(37,28,5,15,1.5,c)]
		"resume": return [_t(17,11,17,45,46,28,c)]
		"stop": return [_s(14,14,42,42,5,c),_s(42,14,14,42,5,c)]
		"repeat": return [_ring(18,28,9,4.4,c),_ring(38,28,9,4.4,c)]
		"deploy": return _figure(15,c)+[_s(28,28,44,28,4.4,c),_t(54,28,42,20,42,36,c)]
		"edit": return [_s(15,41,39,17,7,c),_t(9,47,11,37,19,45,c),_s(37,15,43,21,7,soft)]
		"plus": return [_s(28,12,28,44,5.4,c),_s(12,28,44,28,5.4,c)]
		"minus": return [_s(12,28,44,28,5.4,c)]
		"prio0": return [_s(14,35,28,23,4.6,c),_s(28,23,42,35,4.6,c)]
		"prio1": return [_s(14,29,28,17,4.6,c),_s(28,17,42,29,4.6,c),_s(14,41,28,29,4.6,c),_s(28,29,42,41,4.6,c)]
		"prio2": return [_s(14,23,28,11,4.6,c),_s(28,11,42,23,4.6,c),_s(14,35,28,23,4.6,c),_s(28,23,42,35,4.6,c),_s(14,47,28,35,4.6,c),_s(28,35,42,47,4.6,c)]
		# The War screen (hud/war_board.gd): soldiers' pay, eyes abroad, and
		# the stances toward an enemy that had no mark of their own.
		# Pay: a short stack of coins.
		"coins": return [_rr(28,44,15,4.2,4,c),_rr(28,34,15,4.2,4,soft),_rr(28,24,15,4.2,4,c),_ring(28,13,8,3.2,c)]
		# Eyes abroad: an eye, its pupil inked.
		"eye": return [_s(6,28,17,19,3.2,c),_s(17,19,39,19,3.2,c),_s(39,19,50,28,3.2,c),_s(6,28,17,37,3.2,c),_s(17,37,39,37,3.2,c),_s(39,37,50,28,3.2,c),_c(28,28,7,c)]
		# Leave them be: a spear laid down on the ground.
		"leave": return [_s(6,38,42,38,3.6,c),_t(53,38,41,32,41,44,c),_s(4,48,52,48,2.6,soft)]
		# Seek peace: a plain flag carried on a pole.
		"peace": return [_s(15,53,15,6,3.4,c),_rr(31,17,14,9.5,1.5,c),_s(4,53,26,53,2.6,soft)]
		# A blood price: a tied sack of food.
		"price": return [_c(28,37,14,c),_t(19,15,37,15,28,26,c),_s(20,24,36,24,3.4,soft)]
	return [_c(28,28,6,c)]


# -- Workshops: equipment, materials and the workshop's own marks -------------

static var _equipment_textures:Dictionary={}
static var _material_textures:Dictionary={}
static var _workshop_textures:Dictionary={}
const WORKSHOP_PAPER:=Color(0.95,0.91,0.80,0.9)

## A kind of equipment, inked on a paper halo for the Production screen, its
## stock strip and picker. Weapons reuse the battle view's arm marks; arrows,
## rounds, carts, boats and aircraft are drawn here. accent touches one detail.
static func equipment_texture(item:String,ink:Color,accent:Color,px:int=40)->Texture2D:
	var key:="%s|%s|%s|%d" % [item,ink.to_html(),accent.to_html(),px]
	if _equipment_textures.has(key): return _equipment_textures[key]
	var texture:=ImageTexture.create_from_image(_render_boxed(_with_halo(equipment_glyph(item,ink,accent),WORKSHOP_PAPER,1.4),px))
	_equipment_textures[key]=texture
	return texture


## The mark that stands for this equipment: every land kit draws its own
## glyph from the equipment ledger (equipment_ledger.gd "glyph", the same
## mark its blocks carry in battle); "" when the workshop draws its own
## (arrows, rounds, carts, boats, aircraft: see equipment_kind).
static func equipment_arm(item:String)->String:
	var ledger:=_ledger()
	if ledger!=null and ledger.has(item): return String(ledger.glyph(item))
	# Supply lorries are not a fighting kit but draw as what they are (carts
	# keep their own mark, equipment_kind).
	if item=="supply_lorry": return "lorry"
	return ""


static var _ledger_script:GDScript

## The equipment ledger, loaded on first use (it is data; loading it here
## keeps this icon engine free of a load-order dependency on it).
static func _ledger()->GDScript:
	if _ledger_script==null: _ledger_script=load("res://scripts/equipment_ledger.gd")
	return _ledger_script


## The workshop's own mark for items without a battle arm: arrows, shell,
## cartridges, fuel, cart, canoe, galley, sail, steamship, submarine, plane,
## balloon; "" for weapons (equipment_arm).
static func equipment_kind(item:String)->String:
	match item:
		"arrows": return "arrows"
		"artillery_rounds","heavy_shells": return "shell"
		"small_arms_ammunition": return "cartridges"
		"fuel": return "fuel"
		"transport_cart": return "cart"
	if not item.ends_with("_equipment"): return ""
	if item.begins_with("war_canoe"): return "canoe"
	if item.begins_with("galley") or item.begins_with("heavy_galley"): return "galley"
	if item.begins_with("sailing_") or item.begins_with("ship_of_line"): return "sail"
	if "submarine" in item: return "submarine"
	if item.begins_with("observation_balloon") or item.begins_with("airship"): return "balloon"
	for word in ["fighter","bomber","plane","aircraft","drone","helicopter","close_air"]:
		if word in item and not item.begins_with("aircraft_carrier"): return "plane"
	return "steamship"


static func equipment_glyph(item:String,ink:Color,accent:Color)->Array:
	var arm:=equipment_arm(item)
	if arm!="": return arm_glyph(arm,ink,accent)
	var paper:=Color(0.95,0.91,0.80,1.0)
	match equipment_kind(item):
		"arrows":
			var out:Array=[]
			for k in 3:
				var x:=18.0+k*9.0
				out.append_array([_s(x-4,50,x+4,13,1.8,ink),_t(x+5.2,5,x+0.9,13.2,x+7.3,14.5,ink),_s(x-3.4,47,x-7,43,1.4,ink),_s(x-3.4,47,x+0.6,44,1.4,ink)])
			out.append(_rr(27,33,14,2.2,1,accent))
			return out
		"shell": return [_rr(28,35,6.5,12,1.5,ink),_t(28,9,21.5,23.5,34.5,23.5,ink),_rr(28,41,6.5,1.6,0.5,accent),_rr(28,48.5,7.5,1.6,0.5,ink)]
		"cartridges":
			var rounds:Array=[]
			for x in [18.0,28.0,38.0]: rounds.append_array([_rr(x,37,3.6,9,0.8,ink),_t(x,17,x-3.6,28,x+3.6,28,ink),_s(x-3.6,40,x+3.6,40,1.4,accent)])
			return rounds
		"fuel": return [_rr(28,31,12,15,4,ink),_s(17,23,39,23,1.6,paper),_s(17,39,39,39,1.6,paper),_rr(35,13,2.4,2.4,0.6,accent)]
		"cart": return [_rr(26,26,16,6.5,1.5,ink),_rr(26,24.5,13,3.2,1,paper),_rr(24,21,7,2.6,1.2,accent),_ring(16,39,7,2.4,ink),_ring(36,39,7,2.4,ink),_c(16,39,1.8,ink),_c(36,39,1.8,ink),_s(42,28,53,22,2.4,ink)]
		"canoe": return [_rr(28,37,19,4.2,4.2,ink),_t(5,30,12,37,13,33,ink),_t(51,30,44,37,43,33,ink),_c(26,20,3.4,ink),_rr(26,27,3.2,4.6,2,ink),_s(34,13,22,46,2,ink),_s(8,45,48,45,1.4,accent)]
		"galley":
			var galley:=[_rr(28,34,21,4.6,3,ink),_t(3,36,9,32,9,38,ink),_s(47,32,51,24,2.4,ink),_s(28,33,28,8,2.2,ink),_rr(28,17,9,6.5,1,ink),_rr(28,17,7,4.5,0.6,paper),_s(21,17,35,17,1.8,accent)]
			for x in [14.0,20.0,26.0,32.0,38.0]: galley.append(_s(x,38,x-5,47,1.4,ink))
			return galley
		"sail": return [_rr(28,39,20,4.5,4,ink),_t(4,35,10,35,10,41,ink),_s(20,38,20,8,2,ink),_s(35,38,35,11,2,ink),
			_rr(20,17,7,4,1,ink),_rr(20,28,8.5,4,1,ink),_rr(35,19,6,3.6,1,ink),_rr(35,29,7.5,3.6,1,ink),_t(20,5,29,7.5,20,10,accent)]
		"submarine": return [_rr(28,35,22,5.5,5.5,ink),_rr(25,27,5,4,1,ink),_s(27,23,27,14,1.4,ink),_s(27,14,31,14,1.4,ink),_s(8,44,48,44,1.4,accent)]
		"steamship": return [_rr(28,38,22,5,2,ink),_t(3,32,9,32,9,43,ink),_rr(25,29.5,10,4,1,ink),_rr(33,21,3.2,6,1,ink),_s(29.8,19,36.2,19,1.8,accent),
			_c(37,11,3.5,Color(ink,0.5)),_c(42,7,2.6,Color(ink,0.35)),_s(17,31,17,17,1.6,ink)]
		"plane": return [_s(28,8,28,48,4,ink),_s(8,24,48,24,4.4,ink),_s(19,44,37,44,3,ink),_s(22,6,34,6,1.6,accent)]
		"balloon": return [_c(28,20,13,ink),_s(16,20,40,20,1.6,accent),_s(20,31,24,42,1.2,ink),_s(36,31,32,42,1.2,ink),_rr(28,45,5,3.5,1,ink)]
	return [_rr(28,28,12,12,3,ink),_c(28,28,4,paper)]


## A raw material bare, without the map's disc, for rows on paper.
static func material_texture(resource_name:String,px:int=24)->Texture2D:
	var key:="%s|%d" % [resource_name,px]
	if _material_textures.has(key): return _material_textures[key]
	var glyph:=_glyph(resource_name)
	if resource_name=="Civilian Goods": glyph=[_rr(28,34,14,9,4,Color("#a8784a")),_rr(28,24,16,2.6,1.2,Color("#7a5230")),_s(18,31,38,31,1.4,Color("#7a5230")),_s(18,37,38,37,1.4,Color("#7a5230"))]
	elif resource_name=="Transport Carts": glyph=equipment_glyph("transport_cart",Color("#5a4632"),Color("#a8784a"))
	var texture:=ImageTexture.create_from_image(_render(glyph,px,false))
	_material_textures[key]=texture
	return texture


## The workshop's marks for its header: "bench" (a production line), "anchor"
## (a boatyard), "mend" (a mallet: damaged sets waiting for repair), "hands"
## (a craftsperson at work).
static func workshop_texture(kind:String,ink:Color,px:int=24)->Texture2D:
	var key:="%s|%s|%d" % [kind,ink.to_html(),px]
	if _workshop_textures.has(key): return _workshop_textures[key]
	var glyph:Array
	match kind:
		"bench": glyph=[_rr(28,23,21,3.6,1,ink),_s(13,27,11,46,3,ink),_s(43,27,45,46,3,ink),_s(12,38,44,38,2,ink),_s(22,17,33,13,2.2,ink),_rr(35,12.5,3.4,2.4,0.8,ink)]
		"anchor": glyph=[_ring(28,10,4.2,2.4,ink),_s(28,14,28,46,3,ink),_s(19,20,37,20,2.6,ink),_s(12,33,17,41,3,ink),_s(17,41,28,47,3,ink),_s(28,47,39,41,3,ink),_s(39,41,44,33,3,ink),_t(8,29,15,34,9,37,ink),_t(48,29,41,34,47,37,ink)]
		"mend": glyph=[_rr(28,14,17,6.5,2,ink),_rr(12,14,3,8,1.5,ink),_s(28,20,28,51,6,ink)]
		"hands": glyph=[_c(20,20,5,ink),_rr(20,33,6,8,4,ink),_s(16,41,30,44,3.4,ink),_s(24,30,36,28,2.4,ink),_s(36,28,44,20,2.2,ink),_rr(45,19,4,2.6,1,ink),_rr(40,44,8,3,1,ink)]
		_: glyph=production_glyph(kind,ink)
	var texture:=ImageTexture.create_from_image(_render_boxed(_with_halo(glyph,WORKSHOP_PAPER,1.2),px))
	_workshop_textures[key]=texture
	return texture


## The Production screen's flow chart (hud/production_flow.gd): the makers'
## benches by era and what comes out of them, inked on the 56 grid.
##   benches   knapping (hammerstone striking a flake off a core), basket
##             (a woven basket), kiln (a domed kiln with its fire mouth),
##             anvil (an anvil with a hammer), loom (an upright loom)
##   outputs   homes (a house with goods at its door), barter (a balance),
##             watch (spear and shield), gear (crossed tools)
## Unknown kinds draw a dot, never an error.
static func production_glyph(kind:String,ink:Color)->Array:
	var soft:=Color(ink,0.55)
	match kind:
		"knapping": return [
			_poly([10,44,16,30,30,24,42,30,46,44],ink),
			_t(30,24,24,31,35,30,Color(WORKSHOP_PAPER,1.0)),
			_c(38,14,6.5,ink),_s(33,19,30,23,1.6,soft),
			_t(46,22,52,18,50,27,soft),_t(20,22,15,17,17,25,soft)]
		"basket": return [
			_poly([10,24,46,24,41,46,15,46],ink),
			_s(13,31,43,31,1.4,Color(WORKSHOP_PAPER,0.9)),_s(14,38,42,38,1.4,Color(WORKSHOP_PAPER,0.9)),
			_s(21,25,20,45,1.2,Color(WORKSHOP_PAPER,0.7)),_s(28,25,28,45,1.2,Color(WORKSHOP_PAPER,0.7)),_s(35,25,36,45,1.2,Color(WORKSHOP_PAPER,0.7)),
			_ring(28,24,13,2.4,ink)]
		"kiln": return [
			_c(28,30,16,ink),_rr(28,40,17,8,1,ink),
			_c(28,38,6,Color(WORKSHOP_PAPER,1.0)),_rr(28,42,6,4,0,Color(WORKSHOP_PAPER,1.0)),
			_t(28,33,24,44,32,44,Color("#b5552f")),
			_rr(28,12,3,4,1,ink),_s(27,7,30,2,1.6,soft)]
		"anvil": return [
			_poly([8,22,44,22,48,26,38,30,16,30],ink),
			_rr(27,35,6,5,1,ink),_rr(27,44,13,3.5,1,ink),
			_s(36,6,46,16,3,ink),_rr(33,9,5,3,1,ink)]
		"loom": return [
			_s(12,8,12,48,3,ink),_s(44,8,44,48,3,ink),_s(10,10,46,10,3,ink),_s(10,40,46,40,2.4,ink),
			_s(18,11,18,40,1.1,soft),_s(23,11,23,40,1.1,soft),_s(28,11,28,40,1.1,soft),_s(33,11,33,40,1.1,soft),_s(38,11,38,40,1.1,soft),
			_rr(28,26,15,4,1,ink)]
		"homes": return [
			_t(28,8,8,26,48,26,ink),_rr(28,37,15,11,1,ink),
			_rr(28,41,4,7,1,Color(WORKSHOP_PAPER,1.0)),_rr(40,13,3,6,0.5,ink)]
		"barter": return [
			_s(28,10,28,46,2.6,ink),_s(10,16,46,16,2.4,ink),_rr(28,47,10,2.4,1,ink),
			_s(12,16,7,30,1.2,soft),_s(12,16,17,30,1.2,soft),_rr(12,31,7,2.6,2,ink),
			_s(44,16,39,30,1.2,soft),_s(44,16,49,30,1.2,soft),_rr(44,31,7,2.6,2,ink),
			_c(10,27,2.6,ink),_c(14,27,2.6,ink),_rr(44,26,4,3,1,ink)]
		"watch": return [
			_s(40,52,40,12,2.6,ink),_t(40,2,35,13,45,13,ink),
			_rr(23,30,12,15,10,ink),_rr(23,30,8.5,11.5,7,Color(WORKSHOP_PAPER,0.9)),_c(23,30,3.4,ink)]
		"gear": return [
			_s(12,44,36,20,4,ink),_rr(39,16,6,4,1.5,ink),
			_s(44,44,22,22,2.6,ink),_t(16,12,24,20,18,26,ink)]
	return [_c(28,28,8,ink)]


# -- Logistics: the Forces and Readiness & supply tabs -------------------------

static var _logistics_textures:Dictionary={}

## Small inked marks for the Military screen's Forces and Readiness & supply
## tabs (hud/forces_board.gd, hud/readiness_board.gd), drawn bare like
## command_texture so they sit beside a number. Kinds:
##   carriers  porter (a bearer with his pack), cart, lorry
##   the line  hub (a storehouse in a ring: home or one of our towns),
##             depot (crates under a pennant: a town we hold), road
##   the band  hungry (an empty bowl), seen (a star: fights come through),
##             find (a sighting ring: show it on the map), talk (two speech
##             bubbles: call its general to court)
## Unknown kinds draw a dot, never an error.
static func logistics_texture(kind:String,ink:Color,px:int=40)->Texture2D:
	var key:="%s|%s|%d" % [kind,ink.to_html(),px]
	if _logistics_textures.has(key): return _logistics_textures[key]
	var texture:=ImageTexture.create_from_image(_render(logistics_glyph(kind,ink),px,false))
	_logistics_textures[key]=texture
	return texture


static func logistics_glyph(kind:String,c:Color)->Array:
	var soft:=Color(c,0.5)
	match kind:
		"porter": return _figure(22,c)+[_rr(33,24,6,9,2.5,c),_s(26,18,31,16,2,c),_s(12,20,9,50,2.4,soft)]
		"cart": return [_rr(27,25,17,6,1.5,c),_s(10,17,10,25,2.4,c),_s(44,17,44,25,2.4,c),_ring(18,39,7,3,c),_ring(36,39,7,3,c),_c(18,39,2,c),_c(36,39,2,c),_s(44,27,54,21,2.6,c)]
		"lorry": return [_rr(21,26,15,10,1.5,c),_rr(43,30,8,6,1.5,c),_rr(41,21,5,4,1,c),_s(6,37,51,37,2.4,c),_ring(15,42,5,3,c),_ring(41,42,5,3,c)]
		"hub": return [_ring(28,28,22,3,c),_t(28,11,13,25,43,25,c),_rr(28,34,10,8,1,c)]
		"depot": return [_rr(19,40,9,8,1.2,c),_rr(36,43,6,5,1.2,soft),_s(36,6,36,37,2.6,c),_t(37.5,7,37.5,20,51,13.5,c),_s(8,50,48,50,2.2,soft)]
		"road": return [_s(4,18,52,18,3.2,c),_s(4,38,52,38,3.2,c),_s(7,28,16,28,2.6,c),_s(23,28,33,28,2.6,c),_s(40,28,49,28,2.6,c)]
		"hungry": return [_s(8,27,48,27,3.4,c),_rr(28,33,15,6,6,c),_rr(28,43,7,2.2,1,c),_s(20,8,24,17,2.2,soft),_s(34,8,30,17,2.2,soft)]
		"seen":
			var star:Array=[_c(28,30,7.5,c)]
			for k in 5:
				var a:=-PI*0.5+TAU*float(k)/5.0
				var tip:=Vector2(28,30)+Vector2.from_angle(a)*21.0
				var left:=Vector2(28,30)+Vector2.from_angle(a-PI/5.0)*8.5
				var right:=Vector2(28,30)+Vector2.from_angle(a+PI/5.0)*8.5
				star.append(_t(tip.x,tip.y,left.x,left.y,right.x,right.y,c))
			return star
		"find": return [_ring(28,28,13,3.4,c),_s(28,5,28,14,3.4,c),_s(28,42,28,51,3.4,c),_s(5,28,14,28,3.4,c),_s(42,28,51,28,3.4,c),_c(28,28,3.8,c)]
		"talk": return [_rr(36,33,15,10,6,soft),_t(40,40,48,40,49,50,soft),_rr(21,19,16,11,6,c),_t(12,26,22,28,8,38,c)]
	return [_c(28,28,6,c)]


# -- The town: its works, homes and defences -----------------------------------

static var _town_textures:Dictionary={}

## Small inked marks for the Buildings page's town board (hud/town_works_board.gd),
## drawn bare like command_texture so they sit beside a figure. Kinds:
##   the works   hall (a civic work), homes, shrine, stores, yard, workshop
##   defences    open (open ground), watch (watch posts), earthwork, palisade,
##               wall (walled districts), bastion (a bastion network)
##   the town    builders (a hammer), repair (a mallet), era (rising blocks),
##               lookout (a sighting ring), shield (defenders), danger (a
##               spearhead), watchers (two figures)
## Unknown kinds draw a dot, never an error.
static func town_texture(kind:String,ink:Color,px:int=40)->Texture2D:
	var key:="%s|%s|%d" % [kind,ink.to_html(),px]
	if _town_textures.has(key): return _town_textures[key]
	var texture:=ImageTexture.create_from_image(_render(town_glyph(kind,ink),px,false))
	_town_textures[key]=texture
	return texture


static func town_glyph(kind:String,c:Color)->Array:
	var soft:=Color(c,0.5)
	match kind:
		"hall": return [_t(5,27,28,9,51,27,c),_rr(28,38,19,10,1,c),_rr(28,42,3.6,6,1,soft)]
		"homes": return [_t(28,31,39,20,50,31,soft),_rr(39,39,9,7.5,1,soft),_t(6,28,20,14,34,28,c),_rr(20,38,11,10,1,c)]
		"shrine": return [_t(12,22,28,8,44,22,c),_s(17,23,17,48,3.2,c),_s(39,23,39,48,3.2,c),_s(10,48,46,48,2.6,soft),_c(28,34,4.5,soft)]
		"stores": return [_rr(28,33,13,14,6,c),_rr(28,16,8,3,1,c),_s(17,30,39,30,1.6,soft)]
		"yard": return [_rr(16,40,9,6,1,c),_rr(36,40,9,6,1,c),_rr(26,28,9,6,1,soft),_s(6,48,50,48,2.4,soft)]
		"workshop": return [_rr(28,23,21,3.6,1,c),_s(13,27,11,46,3,c),_s(43,27,45,46,3,c),_s(12,38,44,38,2,soft),_s(22,17,33,13,2.2,c)]
		"open": return [_s(6,46,50,46,2.4,soft),_s(20,46,20,12,2.6,c),_t(21.5,12,38,18,21.5,24,c)]
		"watch": return [_s(19,50,24,20,3.2,c),_s(37,50,32,20,3.2,c),_s(21,40,35,30,2,soft),_rr(28,20,11,2.6,1,c),_rr(28,14,7,4,1,c),_t(16,11,28,3,40,11,c)]
		"earthwork": return [_poly([4,46,15,28,41,28,52,46],c),_s(4,51,52,51,2.4,soft),_s(15,28,41,28,1.6,soft)]
		"palisade":
			var stakes:Array=[_s(5,33,51,33,2.4,soft)]
			for x:float in [10.0,19.0,28.0,37.0,46.0]:stakes.append_array([_s(x,48,x,20,5,c),_t(x-2.5,21,x,11,x+2.5,21,c)])
			return stakes
		"wall": return [_rr(28,36,22,12,1,c),_rr(10,20,3.6,4.5,0.5,c),_rr(22,20,3.6,4.5,0.5,c),_rr(34,20,3.6,4.5,0.5,c),_rr(46,20,3.6,4.5,0.5,c),_rr(28,42,5,6.5,2.5,soft)]
		"bastion": return [_poly([28,5,35,19,51,21,40,33,44,50,28,42,12,50,16,33,5,21,21,19],c),_c(28,28,6,soft)]
		"builders": return [_s(14,49,33,24,4,c),_ob(24,15,44,31,9,c)]
		"repair": return [_rr(28,14,17,6.5,2,c),_rr(12,14,3,8,1.5,soft),_s(28,20,28,51,6,c)]
		"era": return [_rr(13,42,8,7,1,soft),_rr(28,36,8,13,1,c),_rr(43,29,8,20,1,c)]
		"lookout": return [_ring(28,28,12,3.4,c),_c(28,28,4.5,c),_s(3,28,13,28,3,soft),_s(43,28,53,28,3,soft)]
		"shield": return [_poly([12,9,44,9,44,27,28,50,12,27],c),_s(28,14,28,40,2.2,soft)]
		"danger": return [_t(28,5,19,28,37,28,c),_s(28,27,28,52,3.2,c),_s(22,44,34,44,2.4,soft)]
		"watchers": return _figure(20,c)+_figure(36,soft)
	return [_c(28,28,6,c)]
