extends Control
## A question's progress on the Research board: its painting in a small round
## medallion, an inked track around it and the evidence gathered as a gold arc
## in the field's colour. A question without a painting shows its field's
## glyph. Only the arc moves: set_value() eases it to the day's evidence, so a
## card never changes size or place as the work goes on.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Painting:=preload("res://scripts/hud/subject_painting.gd")
## The painting (or the field glyph when there is none).
var texture:Texture2D:
	set(value):
		texture=value
		queue_redraw()
## Where the painting is cropped around (0..1 of its width and height).
var focus:=Vector2(0.5,0.5)
## True when `texture` is a field glyph drawn whole rather than a painting.
var glyph:=false
var accent:=Color("8a6118")
## Evidence gathered, 0..1, as drawn now.
var value:=0.0:
	set(amount):
		value=clampf(amount,0.0,1.0)
		queue_redraw()
## A line waiting on something (goods, a material): the track is drawn amber.
var held:=false:
	set(flag):
		held=flag
		queue_redraw()
var _tween:Tween

func _init()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(44,44)

## Eases the arc to `amount`; draws it at once when `animate` is false or the
## arc is not on screen yet.
func set_value(amount:float,animate:=true)->void:
	amount=clampf(amount,0.0,1.0)
	if is_equal_approx(amount,value):return
	if _tween!=null and _tween.is_valid():_tween.kill()
	if not animate or not is_inside_tree():
		value=amount
		return
	_tween=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self,"value",amount,preload("res://scripts/hud/motion.gd").duration(preload("res://scripts/hud/motion.gd").BASE))

func _draw()->void:
	var side:=minf(size.x,size.y)
	var center:=size*0.5
	var ring:=maxf(4.0,side*0.12)
	var radius:=side*0.5-ring*0.5-0.5
	var inner:=radius-ring*0.5-1.5
	# The medallion: the painting cropped to a disc, or the glyph on paper.
	draw_circle(center,inner,T.TILE_BG)
	if texture!=null and texture.get_width()>0 and texture.get_height()>0:
		if glyph:
			var box:=inner*1.5
			draw_texture_rect(texture,Rect2(center-Vector2(box,box)*0.5,Vector2(box,box)),false)
		else:
			_draw_disc(center,inner)
	draw_arc(center,inner+0.5,0.0,TAU,48,Color(T.INK,0.35),1.0,true)
	# The track and the evidence gathered.
	draw_arc(center,radius,0.0,TAU,64,Color(T.AMBER,0.55) if held else Color(T.TRACK,0.7),ring,true)
	if value>0.0:
		var start:=-PI*0.5
		draw_arc(center,radius,start,start+TAU*value,maxi(8,int(64*value)),T.legible(accent,T.ROW_BG,3.0),ring,true)

## The painting drawn as a disc: a polygon with the texture's crop as its UVs.
func _draw_disc(center:Vector2,radius:float)->void:
	var drawn:Texture2D=texture
	var region:=Painting.crop_region(texture,Vector2(radius*2.0,radius*2.0),focus)
	if region.size.x<=0.0 or region.size.y<=0.0:region=Rect2(Vector2.ZERO,texture.get_size())
	# A framed part of a larger sheet: the UVs are the sheet's.
	if texture is AtlasTexture and (texture as AtlasTexture).atlas!=null:
		region.position+=(texture as AtlasTexture).region.position
		drawn=(texture as AtlasTexture).atlas
	var source:=Vector2(drawn.get_width(),drawn.get_height())
	var points:=PackedVector2Array()
	var uvs:=PackedVector2Array()
	var steps:=40
	for index in steps:
		var angle:=TAU*float(index)/float(steps)
		var unit:=Vector2(cos(angle),sin(angle))
		points.append(center+unit*radius)
		var at:=region.position+region.size*(unit*0.5+Vector2(0.5,0.5))
		uvs.append(Vector2(at.x/source.x,at.y/source.y))
	draw_colored_polygon(points,Color.WHITE,uvs,drawn)
