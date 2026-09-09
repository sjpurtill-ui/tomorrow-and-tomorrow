extends RefCounted
const IDENTITIES=preload("res://scripts/civilization_identity.gd")
static var cache:Dictionary={}
static var cache_seed:int=-9223372036854775807
const SYMBOLS:=[
	'<circle cx="33" cy="20" r="7"/><path d="M33 9 V5 M33 31 V35 M22 20 H18 M44 20 H48" stroke="currentColor" stroke-width="3"/>',
	'<path d="M38 9 C21 5 18 30 38 31 C27 24 27 16 38 9 Z"/>',
	'<path d="M33 8 L44 20 L33 32 L22 20 Z"/>',
	'<path d="M33 7 L37 16 L47 17 L40 23 L42 33 L33 28 L24 33 L26 23 L19 17 L29 16 Z"/>',
	'<path d="M33 7 L24 17 H28 L21 25 H30 V33 H36 V25 H45 L38 17 H42 Z"/>',
	'<path d="M17 29 L29 10 L35 19 L40 13 L51 29 Z"/>',
	'<path d="M17 16 Q25 9 33 16 T49 16 M17 25 Q25 18 33 25 T49 25" fill="none" stroke="currentColor" stroke-width="5"/>',
	'<path d="M24 9 H29 V14 H32 V9 H36 V14 H39 V9 H44 V19 L41 22 V32 H27 V22 L24 19 Z"/>',
	'<path d="M18 12 L32 19 L48 9 L41 22 L31 31 L29 23 L21 21 Z"/>',
	'<path d="M33 5 L40 15 H36 V33 H30 V15 H26 Z"/>',
	'<path d="M19 11 L27 18 L33 9 L39 18 L47 11 L43 29 H23 Z"/>',
	'<circle cx="33" cy="20" r="10" fill="none" stroke="currentColor" stroke-width="4"/><path d="M33 10 V30 M23 20 H43" stroke="currentColor" stroke-width="4"/>'
]

static func flag_svg(identity:Dictionary)->String:
	var field:=String(identity.field);var ink:=String(identity.ink);var pattern:=""
	match int(identity.pattern):
		1:pattern='<path d="M5 5 H23 V35 H5 Z" fill="#%s"/>' % ink
		2:pattern='<path d="M5 26 H60 V35 H5 Z" fill="#%s"/>' % ink
		3:pattern='<path d="M5 5 H60 L5 35 Z" fill="#142938"/>'
		4:pattern='<path d="M5 5 L24 20 L5 35 Z" fill="#%s"/>' % ink
		5:pattern='<path d="M5 5 H23 V17 H5 Z" fill="#%s"/>' % ink
		6:pattern='<path d="M5 9 H60 M5 31 H60" stroke="#%s" stroke-width="4"/>' % ink
		7:pattern='<path d="M5 5 H60 V35 H5 Z" fill="none" stroke="#%s" stroke-width="5"/>' % ink
	# A dark keyline keeps the emblem legible on every divided field at map size.
	var symbol:=String(SYMBOLS[int(identity.symbol)])
	return '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="40" viewBox="0 0 64 40"><path d="M2 2 V39" stroke="#ede3c9" stroke-width="2"/><rect x="5" y="5" width="55" height="30" fill="#%s"/>%s<g color="#14232d" fill="#14232d" stroke="#14232d" stroke-width="3" stroke-linejoin="round">%s</g><g color="#%s" fill="#%s">%s</g><rect x="5" y="5" width="55" height="30" fill="none" stroke="#14232d" stroke-width="1"/></svg>' % [field,pattern,symbol.replace("currentColor","#14232d"),ink,ink,symbol.replace("currentColor","#"+ink)]

static func foreign(civ_id:String)->Dictionary:
	if cache_seed!=GameState.world_seed:cache.clear();cache_seed=GameState.world_seed
	if cache.has(civ_id):return cache[civ_id]
	var identity:Dictionary=IDENTITIES.identity(GameState.world_seed,civ_id).duplicate()
	if civ_id.is_empty():identity={"field":"7c8588","color":"bdc6c7","ink":"e7e4d4","pattern":0,"symbol":2}
	var image:=Image.new();image.load_svg_from_string(flag_svg(identity))
	if cache.size()>=128:cache.clear()
	cache[civ_id]={"color":Color(String(identity.color)),"texture":ImageTexture.create_from_image(image)}
	return cache[civ_id]
static func banner_color(texture:Texture2D)->Color:
	if texture==null:return Color("e4c67a")
	var image:=texture.get_image()
	var sum:=Vector3.ZERO;var weight:=0.0
	for y in range(0,image.get_height(),4):
		for x in range(0,image.get_width(),4):
			var c:=image.get_pixel(x,y)
			var w:=c.a*c.s*c.s*c.v
			sum+=Vector3(c.r,c.g,c.b)*w;weight+=w
	if weight<=.001:return Color("e4c67a")
	var color:=Color(sum.x/weight,sum.y/weight,sum.z/weight)
	return Color.from_hsv(color.h,maxf(.35,color.s),maxf(.88,color.v))
