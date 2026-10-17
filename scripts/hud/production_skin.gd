extends RefCounted
## Scoped industrial palette: never changes the global HUD's chosen theme.
const W=preload("res://scripts/hud/production_widgets.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const INK:=Color("dedcc8")
const BG:=Color("252a25")
const EDGE:=Color("626650")
static var normal:StyleBoxFlat
static var hover:StyleBoxFlat
static var selected:StyleBoxFlat
static var disabled:StyleBoxFlat
static func apply(root:Node)->void:
	if normal==null:
		normal=flat(Color("383e32"),EDGE,1,1,3)
		hover=flat(Color("535c43"),Color("aaa983"),1,1,3)
		selected=flat(Color("596344"),Color("aaa983"),1,1,3)
		disabled=flat(Color("292e27"),Color("424837"),1,1,3)
	for child:Node in root.get_children():
		if child is Button:
			var button:=child as Button
			if button.get_parent().name!="CapacityGrid":
				button.add_theme_stylebox_override("normal",selected if button.button_pressed else normal)
				button.add_theme_stylebox_override("hover",hover);button.add_theme_stylebox_override("pressed",selected);button.add_theme_stylebox_override("disabled",disabled)
				button.custom_minimum_size.y=28
				if button is W.IconButton:button.custom_minimum_size=Vector2(26,26);button.ink_override=INK
			for kind in ["font_color","font_hover_color","font_pressed_color"]:button.add_theme_color_override(kind,INK)
			button.add_theme_color_override("font_disabled_color",Color("737966"));button.add_theme_font_size_override("font_size",13)
		elif child is Label:
			if child.name!="ResourcePenalty":child.add_theme_color_override("font_color",INK)
			child.add_theme_font_size_override("font_size",13)
		apply(child)

static func flat(bg:Color,border:Color=Color.TRANSPARENT,width:int=0,radius:int=0,pad:float=0)->StyleBoxFlat:
	var style:=T.flat(bg,border,width,radius,pad)
	style.bg_color=bg
	return style
