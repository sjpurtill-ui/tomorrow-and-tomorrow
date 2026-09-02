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


static func _render(primitives:Array)->Image:
	var image:=Image.create(ICON_PX,ICON_PX,false,Image.FORMAT_RGBA8)
	var stack:Array=[
		_c(28,28,25,Color(0.035,0.066,0.060,0.88)),
		_ring(28,28,24.0,1.6,Color(0.87,0.82,0.70,0.55)),
	]
	stack.append_array(primitives)
	for y in ICON_PX:
		for x in ICON_PX:
			var p:=Vector2(x+0.5,y+0.5)
			var out:=Color(0,0,0,0)
			for primitive_variant in stack:
				var primitive:Dictionary=primitive_variant
				var coverage:=clampf(0.5-_sd(primitive,p),0.0,1.0)*(primitive.col as Color).a
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
	return [_c(28,28,10,c)]
