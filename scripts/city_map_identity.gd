extends RefCounted
# Stable presentation derived from identity; no simulation authority or save fields.
static var cache:Dictionary={}
static func foreign(civ_id:String)->Dictionary:
	if cache.has(civ_id):return cache[civ_id]
	var seed_value:=int(civ_id.hash())
	var color:=Color.from_hsv(fmod(float(seed_value%997)*0.61803398875,1.0),.57,.95) if civ_id!="" else Color("b8b6ae")
	var motif:=""
	match seed_value%4:
		0:motif='<path d="M5 7 L57 33" stroke="#fff0c9" stroke-width="6"/>'
		1:motif='<path d="M5 20 H57" stroke="#fff0c9" stroke-width="7"/>'
		2:motif='<path d="M24 7 V33" stroke="#fff0c9" stroke-width="7"/>'
		3:motif='<path d="M31 10 L43 20 L31 30 L19 20 Z" fill="#fff0c9"/>'
	var svg:='<svg xmlns="http://www.w3.org/2000/svg" width="64" height="40"><path d="M3 3 V38" stroke="#eee2c4" stroke-width="3"/><path d="M5 6 H59 L53 20 L59 34 H5 Z" fill="#%s" stroke="#111a1b" stroke-width="2"/>%s</svg>' % [color.to_html(false),motif]
	var image:=Image.new();image.load_svg_from_string(svg)
	cache[civ_id]={"color":color,"texture":ImageTexture.create_from_image(image)}
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
