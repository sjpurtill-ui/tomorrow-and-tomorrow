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
## megalopolis), then a stranger's reported town.
const SETTLEMENT_GLYPH_FOREIGN:=7
const SETTLEMENT_GLYPH_COUNT:=8
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
	return float([14.0,16.0,18.0,20.0,22.0,24.4,27.1,22.0][clampi(index,0,SETTLEMENT_GLYPH_COUNT-1)])/float(ICON_PX)

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


# -- Battle figures ---------------------------------------------------------

static var _figure_textures:Dictionary={}

## One fighter for the battle replay, inked on a paper halo, weapon by era
## and arm: "club" (a hearth band's clubs and sharpened sticks), "spear",
## "bow", "sword" (sword and shield), "musket", "rifle", "horse" (a rider),
## and "fallen" (a fighter down). The owner's colour touches only a sash.
static func battle_figure_texture(kind:String,ink:Color,accent:Color,px:int=64)->Texture2D:
	var key:="%s|%s|%s|%d" % [kind,ink.to_html(),accent.to_html(),px]
	if _figure_textures.has(key): return _figure_textures[key]
	var texture:=ImageTexture.create_from_image(_render_boxed(_with_halo(battle_figure_glyph(kind,ink,accent),Color(0.95,0.91,0.80,0.9),2.2),px))
	_figure_textures[key]=texture
	return texture


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
