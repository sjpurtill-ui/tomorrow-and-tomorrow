extends RefCounted
## Fort anchors for the field atlas. The existing era-specific plan is kept;
## an engraved paper rim separates its fine walls from the coloured ground.
## This is map paper, independent of the HUD's day/night reading preference.

const Icons:=preload("res://scripts/resource_icons.gd")
const PAPER:=Color("f2e7cf")
const GLYPH_PX:=96
const CACHE_LIMIT:=128
static var _textures:Dictionary={}

## Keep the sprite's screen size when replacing its lower-resolution glyph.
## Only the ink fades with staffing. Paper stays readable over dark terrain.
static func finish(mark:Sprite3D,kind:String,ink:Color)->void:
	var old_pixels:=float(mark.texture.get_width())
	mark.texture=texture(kind,ink)
	mark.pixel_size*=old_pixels/float(mark.texture.get_width())
	mark.modulate=Color.WHITE

static func texture(kind:String,ink:Color)->Texture2D:
	# A handful of tonal steps avoids a new texture for each garrison change.
	ink.a=snappedf(clampf(ink.a,0.0,1.0),0.1)
	var key:="%s|%s" % [kind,ink.to_html()]
	if _textures.has(key):return _textures[key]
	var glyph:Array=[Icons._c(28,28,25.5,Color(PAPER,0.28)),
		Icons._c(28,28,23.8,Color(PAPER,0.96)),
		Icons._ring(28,28,23.0,0.85,Color(ink,0.38))]
	glyph.append_array(Icons._chart_glyph(kind,ink))
	var out:=ImageTexture.create_from_image(Icons._render(glyph,GLYPH_PX,false))
	if _textures.size()>=CACHE_LIMIT:_textures.clear()
	_textures[key]=out
	return out
