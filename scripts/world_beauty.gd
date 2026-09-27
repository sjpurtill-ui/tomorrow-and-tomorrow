extends RefCounted
## World beauty palette, readable from GDScript (codex/world-beauty).
##
## The terrain shader paints the known land from a biome palette in
## scripts/world_beauty.gdshaderinc. That file is the one source of the colours:
## this helper reads its `const vec3 WB_*` values from the shader text and
## mirrors wb_biome_palette() so tests, legends or any 2D view can ask "what
## colour is this land?" and get the same answer the map paints.
## Visual only; nothing here feeds the simulation or the save.

const INCLUDE_PATH:="res://scripts/world_beauty.gdshaderinc"

static var _palette:Dictionary={}


## The palette constants (sRGB, 0-1) keyed by name without the WB_ prefix,
## e.g. "MEADOW", "STEPPE", "WOOD".
static func palette()->Dictionary:
	if not _palette.is_empty():return _palette
	var file:=FileAccess.open(INCLUDE_PATH,FileAccess.READ)
	if file==null:return _palette
	var pattern:=RegEx.new()
	pattern.compile("const vec3 WB_([A-Z_]+)\\s*=\\s*vec3\\(([-0-9.]+),\\s*([-0-9.]+),\\s*([-0-9.]+)\\)")
	for found in pattern.search_all(file.get_as_text()):
		_palette[found.get_string(1)]=Color(float(found.get_string(2)),float(found.get_string(3)),float(found.get_string(4)))
	return _palette


static func _smooth(edge0:float,edge1:float,x:float)->float:
	return smoothstep(edge0,edge1,x)


## Mirror of wb_biome_palette() in the shader, returning sRGB. rain and warm
## are the climate fields (0-1), forest the woodland cover, height in km, and
## pattern the painter's broken-wash noise (0.5 is neutral-ish).
static func biome_colour(rain:float,warm:float,forest:float,height:float,pattern:float=0.5)->Color:
	var p:=palette()
	if p.is_empty():return Color.BLACK
	var lush:=_smooth(0.52,0.86,rain)
	var dry:=1.0-_smooth(0.26,0.50,rain)
	var arid:=(1.0-_smooth(0.08,0.26,rain))*_smooth(0.35,0.65,warm)
	var cold:=1.0-_smooth(0.13,0.30,warm)
	var open:Color=(p.MEADOW as Color).lerp(p.MEADOW_LUSH,lush)
	open=open.lerp(p.STEPPE,dry)
	open=open.lerp(p.DRYLAND,arid)
	var marsh:=_smooth(0.72,0.92,rain)*(1.0-_smooth(0.15,0.9,height))
	open=open.lerp(p.WETLAND,marsh*0.65)
	open=open.lerp(p.TUNDRA,cold*0.85)
	open=_tint(open,Color(1.04,1.02,0.94).lerp(Color(0.96,1.00,1.05),pattern))
	var wood:Color=(p.WOOD as Color).lerp(p.WOOD_COLD,maxf(cold,1.0-_smooth(0.25,0.45,warm))*0.8)
	wood=wood.lerp(p.WOOD_DRY,dry*0.7)
	wood=_tint(wood,Color(1.03,1.02,0.95).lerp(Color(0.95,1.0,1.04),pattern))
	var c:=open.lerp(wood,clampf(forest,0.0,1.0))
	c=c.lerp(p.UPLAND,_smooth(4.5,9.0,height)*0.7)
	return Color(clampf(c.r,0,1),clampf(c.g,0,1),clampf(c.b,0,1))


static func _tint(c:Color,t:Color)->Color:
	return Color(c.r*t.r,c.g*t.g,c.b*t.b)
