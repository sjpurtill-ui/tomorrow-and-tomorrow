extends RefCounted
const IDENTITIES=preload("res://scripts/civilization_identity.gd")
static var cache:Dictionary={}
static var cache_seed:int=-9223372036854775807
static var player_crests:Dictionary={}
const CREST_FIELDS:=["74513c","596251","826b43","4b6265","755b56","5c6651","77684f","5b5969","6c6151","4d6762"]
const CREST_SIGILS:=[
	'<path d="M36 49 V24 M36 39 L27 31 M36 35 L45 27 M29 48 H43"/>',
	'<path d="M25 46 Q25 34 36 34 Q47 34 47 46 M29 27 A7 7 0 1 0 43 27 A7 7 0 1 0 29 27"/>',
	'<path d="M25 47 H47 M28 38 H44 M31 29 H41 M36 21 V50"/>',
	'<path d="M25 48 L25 26 M47 48 L47 26 M25 34 H47 M30 21 L30 50 M42 21 L42 50"/>',
	'<path d="M24 30 L36 21 L48 30 V43 L36 51 L24 43 Z M28 39 H44"/>',
	'<path d="M22 28 Q29 22 36 28 T50 28 M22 44 Q29 38 36 44 T50 44 M36 26 V46"/>',
	'<path d="M25 22 H47 M29 22 V49 M43 22 V49 M25 49 H47 M26 34 H46"/>',
	'<circle cx="36" cy="35" r="11"/><path d="M36 20 V15 M36 55 V50 M21 35 H16 M56 35 H51"/>',
	'<path d="M22 49 Q24 29 36 21 Q48 29 50 49 M28 45 Q36 37 44 45"/>',
	'<path d="M25 23 L36 32 L47 23 M25 35 L36 44 L47 35 M25 47 L36 55 L47 47"/>',
	'<path d="M22 24 L32 35 L22 46 M50 24 L40 35 L50 46 M36 20 V50"/>',
	'<path d="M25 48 L25 26 L36 21 L47 26 L47 48 M31 33 H41 M31 40 H41"/>'
]

static func crest_svg(identity:Dictionary)->String:
	var field:=Color(String(identity.field)).lerp(Color("6a5847"),0.42).to_html(false)
	var symbol:=String(CREST_SIGILS[posmod(int(identity.symbol),CREST_SIGILS.size())])
	var marks:=""
	match posmod(int(identity.pattern),4):
		1:marks='<circle cx="36" cy="11" r="2"/><circle cx="36" cy="61" r="2"/>'
		2:marks='<path d="M12 36 H17 M55 36 H60"/>'
		3:marks='<path d="M18 18 L22 22 M50 50 L54 54"/>'
	return '<svg xmlns="http://www.w3.org/2000/svg" width="72" height="72" viewBox="0 0 72 72"><circle cx="36" cy="36" r="33" fill="#e8dcc0" stroke="#302e28" stroke-width="2"/><circle cx="36" cy="36" r="28" fill="#%s" stroke="#302e28" stroke-width="2"/><circle cx="36" cy="36" r="23" fill="none" stroke="#e8dcc0" stroke-width="1.5"/><g fill="none" stroke="#f5edda" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">%s</g><g fill="#f5edda" stroke="#f5edda" stroke-width="1.5">%s</g></svg>' % [field,symbol,marks]

static func player_crest(index:int)->Texture2D:
	var selected:=clampi(index,0,9)
	if player_crests.has(selected):return player_crests[selected]
	var image:=Image.new()
	var identity:={"field":CREST_FIELDS[selected],"symbol":selected,"pattern":selected}
	if image.load_svg_from_string(crest_svg(identity),3.0)!=OK:return null
	image.generate_mipmaps()
	player_crests[selected]=ImageTexture.create_from_image(image)
	return player_crests[selected]

static func foreign(civ_id:String)->Dictionary:
	if cache_seed!=WorldSimulation.state.world_seed:cache.clear();cache_seed=WorldSimulation.state.world_seed
	if cache.has(civ_id):return cache[civ_id]
	var identity:Dictionary=IDENTITIES.identity(WorldSimulation.state.world_seed,civ_id).duplicate()
	if civ_id.is_empty():identity={"field":"7c8588","color":"bdc6c7","ink":"e7e4d4","pattern":0,"symbol":2}
	var image:=Image.new();image.load_svg_from_string(crest_svg(identity),3.0);image.generate_mipmaps()
	if cache.size()>=128:cache.clear()
	cache[civ_id]={"color":Color(String(identity.color)).lerp(Color("e5d5b7"),0.65),"texture":ImageTexture.create_from_image(image)}
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
