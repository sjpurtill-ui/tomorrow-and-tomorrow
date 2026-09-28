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
##   "formation" a staff-map box with the branch symbol.
## branch: foot, horse, missile, guns, engineers, motor, armour. ink draws
## the strokes; accent (the owner's colour) touches only the streamer, the
## tally's tie or a wash on the cloth.
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
	return [diagonal_a,diagonal_b]


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
		2: return Rect2(a,Vector2.ZERO).expand(primitive.b).grow(float(primitive.r))
		3: return Rect2(a,Vector2.ZERO).expand(primitive.b).expand(primitive.c)
		4: return Rect2(a-(primitive.b as Vector2),(primitive.b as Vector2)*2.0)
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
			# Broken walls in faded ink, with the scorch of a fire across them.
			var faded:=Color("#6b5e4e")
			return [_d(28,28,22,halo),_d(28,28,19,Color(paper,0.8)),
				_s(28,11,36,19,2.6,faded),_s(45,28,37,36,2.6,faded),_s(28,45,20,37,2.6,faded),_s(11,28,19,20,2.6,faded),
				_s(19,19,37,37,2.2,Color("#8e3b2e")),_s(37,19,19,37,2.2,Color("#8e3b2e"))]
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

## The arm a block fights as, drawn as its weapon or mount, inked on a paper
## halo (hud/battle_panel.gd plates): club, spear, pike, sword, axe, bow,
## sling, javelin, horse, chariot, elephant, musket, rifle, machine_gun,
## guns, armour, engineers, support. accent touches one small detail.
static func arm_texture(arm:String,ink:Color,accent:Color,px:int=48)->Texture2D:
	var key:="%s|%s|%s|%d" % [arm,ink.to_html(),accent.to_html(),px]
	if _arm_textures.has(key): return _arm_textures[key]
	var texture:=ImageTexture.create_from_image(_render_boxed(_with_halo(arm_glyph(arm,ink,accent),Color(0.95,0.91,0.80,0.9),1.6),px))
	_arm_textures[key]=texture
	return texture


static func arm_glyph(arm:String,ink:Color,accent:Color)->Array:
	var paper:=Color(0.95,0.91,0.80,1.0)
	match arm:
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
		"horse", "chariot":
			if arm=="chariot":
				return [_ring(19,40,9,2.4,ink),_s(19,31,19,49,1.4,ink),_s(10,40,28,40,1.4,ink),_rr(32,30,10,7,1.5,ink),_s(41,33,53,41,2.2,ink),_c(32,17,3.6,ink),_s(32,20,32,25,2.8,ink),_s(29,22,36,24,1.6,accent)]
			return battle_figure_glyph("horse",ink,accent)
		"elephant": return [_rr(28,30,15,10,9,ink),_c(44,24,8,ink),_s(50,28,52,46,3.2,ink),_s(19,36,19,49,4.4,ink),_s(33,36,33,49,4.4,ink),_c(41,21,3.6,accent),_s(45,32,49,36,1.6,paper)]
		"musket": return [_s(11,45,48,12,2.4,ink),_t(6,52,18,43,11,38,ink),_c(22,36,2.6,ink),_s(24,39,26,43,1.6,accent)]
		"rifle": return [_s(11,45,45,15,2.2,ink),_s(45,15,52,8,1.4,ink),_t(6,52,17,43,11,38,ink),_rr(27,33,2.2,3.4,0.6,ink),_s(17,38,32,26,1.2,accent)]
		"machine_gun": return [_s(12,22,48,22,3.2,ink),_rr(19,22,7,5.5,1.2,ink),_s(22,27,13,46,2.2,ink),_s(22,27,31,46,2.2,ink),_s(22,27,22,46,2.2,ink),_s(16,29,10,38,1.8,accent)]
		"guns": return [_s(15,34,47,18,5.6,ink),_ring(20,41,8,2.6,ink),_c(20,41,2.2,ink),_s(20,41,7,49,2.6,ink),_c(48,17,2.0,accent)]
		"armour": return [_rr(28,39,20,6,5.5,ink),_rr(28,32,17,4,1.5,ink),_rr(25,24,9,5,2.5,ink),_s(33,23,51,20,2.6,ink),_c(15,39,2.0,paper),_c(23,39,2.0,paper),_c(31,39,2.0,paper),_c(39,39,2.0,paper),_s(20,24,29,24,1.4,accent)]
		"engineers": return [_s(14,47,40,15,2.4,ink),_rr(43,11,4.4,6,1.8,ink),_s(14,15,40,47,2.4,ink),_s(8,21,21,7,2.8,ink),_c(27,31,2.2,accent)]
		"support": return [_rr(28,25,15,9,1.5,ink),_ring(19,39,5.5,2.2,ink),_ring(37,39,5.5,2.2,ink),_s(43,24,53,18,2.2,ink),_s(28,19,28,31,2.4,paper),_s(22,25,34,25,2.4,paper)]
	return [_c(28,28,8,ink)]


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


## The battle arm whose mark stands for this equipment, or "" when the
## workshop draws its own (see equipment_kind).
static func equipment_arm(item:String)->String:
	match item:
		"improvised": return "club"
		"spear","shield_spear","padded_spear","lamellar_spear","scale_spear","mail_spear","plate_spear": return "spear"
		"javelin": return "javelin"
		"bow","mounted_bow","crossbow": return "bow"
		"sling": return "sling"
		"sword_shield": return "sword"
		"axe": return "axe"
		"pike": return "pike"
		"lance","armored_lance","dragoon_kit": return "horse"
		"chariot_kit": return "chariot"
		"elephant_kit": return "elephant"
		"siege_kit","ram","engineering_kit","repair_kit": return "engineers"
		"catapult","trebuchet","bombard","field_gun","horse_gun","mortar","rocket_launcher","modern_field_gun","anti_air_gun","anti_tank_kit": return "guns"
		"hand_cannon","musket","grenadier_kit": return "musket"
		"service_rifle","marksman_rifle","assault_kit","marine_kit","airborne_kit","mountain_kit","air_assault_kit": return "rifle"
		"machine_gun": return "machine_gun"
		"armored_vehicle","armored_car_kit","light_tank_kit","heavy_tank_kit","tank_destroyer_kit","mechanized_kit": return "armour"
		"motorized_kit","medical_kit": return "support"
	return ""


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
		_: glyph=[_c(28,28,8,ink)]
	var texture:=ImageTexture.create_from_image(_render_boxed(_with_halo(glyph,WORKSHOP_PAPER,1.2),px))
	_workshop_textures[key]=texture
	return texture
