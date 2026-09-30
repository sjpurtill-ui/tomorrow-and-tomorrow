extends Control
## Resolution-independent product silhouettes, not unrelated resource artwork.
var item:String=""
var resource:String=""
const INK:=Color("#dacba5")
const WOOD:=Color("#b98c60")
const Icons:=preload("res://scripts/resource_icons.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
func _ready()->void:
	custom_minimum_size=Vector2(34,34)
	size_flags_vertical=Control.SIZE_SHRINK_CENTER
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw()->void:
	# A land kit is drawn as its own ledger glyph, the mark its blocks carry
	# in battle and its line carries on the Production screen.
	if Icons.equipment_arm(item)!="":
		draw_texture_rect(Icons.equipment_texture(item,T.INK,T.GOLD,64),Rect2(Vector2.ZERO,size),false)
		return
	draw_set_transform(Vector2.ZERO,0,size/Vector2(36,36))
	if item=="transport_cart":
		draw_style_box(_box(Color("#70573e")),Rect2(5,10,21,11))
		draw_line(Vector2(5,23),Vector2(32,23),WOOD,2,true)
		for x:float in [10,24]:draw_arc(Vector2(x,26),5,0,TAU,24,INK,2,true)
	elif "paper" in item or resource in ["Paper","Printed Sheets"]:
		draw_style_box(_box(Color("#c8bc98")),Rect2(8,4,21,27))
		for y:float in [11,16,21,26]:draw_line(Vector2(12,y),Vector2(24,y),Color("#675d47"),1,true)
	elif item=="arrows":
		for offset:int in [0,7]:
			draw_line(Vector2(6+offset,30),Vector2(24+offset,6),WOOD,2,true)
			draw_colored_polygon(PackedVector2Array([Vector2(21+offset,6),Vector2(28+offset,2),Vector2(27+offset,11)]),INK)
	else:
		# Explicit workshop/product category fallback: a gear, not false item art.
		draw_arc(Vector2(18,18),9,0,TAU,32,INK,3,true)
		draw_circle(Vector2(18,18),3,WOOD)
		for tooth:int in 8:
			var direction:=Vector2.RIGHT.rotated(tooth*TAU/8)
			draw_line(Vector2(18,18)+direction*10,Vector2(18,18)+direction*14,INK,4,true)
func _box(color:Color)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(2);return style
