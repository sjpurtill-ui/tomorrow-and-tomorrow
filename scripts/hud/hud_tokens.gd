class_name HudTokens
## Design tokens for the Command Rail HUD (design resolution 1920x1080).
## Source: design_handoff_command_rail_hud/README.md — values are final.

# Runtime palette. DisplayPreferences sets it before the HUD is constructed.
static var color_mode:="light"
static var PANEL_BG:=Color("f3efe6f0")
static var PANEL_BG_SOLID:=Color("f6f2e9f8")
static var DOCK_BG:=Color("f7f3eafa")
static var TILE_BG:=Color("eae4d8")
static var ROW_BG:=Color("f0ebe1")
static var ACTIVE_BG:=Color("ded6c7")
static var HOVER_BG:=Color("e6dfd2")
static var CLOSE_HOVER_BG:=Color("ead8d1")
static var BUTTON_BG:=Color("e9e2d5")
static var FIELD_BG:=Color("fbf8f0")
static var SPEED_IDLE_BG:=Color("ece6da")
static var TRACK:=Color("d5cdbf")
static var TOOLBAR_BG:=Color("f5f1e8ed")
static var MAP_LABEL_BG:=Color("f7f3ead9")
static var BORDER:=Color("aaa08e")
static var BORDER_2:=Color("988e7d")
static var BORDER_SOFT:=Color("c6bdad")
static var LAYER_ON_BORDER:=Color("537d76")
static var INK:=Color("252a28")
static var BODY:=Color("353b38")
static var BODY_2:=Color("464c48")
static var TEXT_SOFT:=Color("59625d")
static var TEXT_DIM:=Color("66706a")
static var MUTED:=Color("737d77")
static var DISABLED:=Color("929a95")
static var LAYER_ON_FG:=Color("343b37")
static var GOLD:=Color("8d6c20")
static var GOLD_BRIGHT:=Color("6e5214")
static var GOLD_WASH:=Color(141.0/255.0,108.0/255.0,32.0/255.0,0.12)
static var GREEN:=Color("647a3e")
static var RED:=Color("a64f40")
static var AMBER:=Color("8c6d28")
static var TEAL:=Color("427c73")
static var BLUE:=Color("596d91")
static var VIOLET:=Color("735f92")
static var DARK_INK:=Color("111111")
static var GLYPH_DARK:=Color("f4efe5")
static var WARN_BG:=Color(141.0/255.0,108.0/255.0,32.0/255.0,0.10)
static var WARN_BORDER:=Color("8d6c20")
static var DANGER_BG:=Color(166.0/255.0,79.0/255.0,64.0/255.0,0.10)
static var DANGER_BORDER:=Color("a64f40")
static var INFO_BG:=Color(66.0/255.0,124.0/255.0,115.0/255.0,0.10)
static var INFO_BORDER:=Color("427c73")
static var _control_theme:Theme

static func set_color_mode(mode:String)->void:
	color_mode="dark" if mode=="dark" else "light"
	_control_theme=null
	if color_mode=="dark":
		PANEL_BG=Color(8.0/255.0,13.0/255.0,15.0/255.0,0.94);PANEL_BG_SOLID=Color(8.0/255.0,13.0/255.0,15.0/255.0,0.97);DOCK_BG=Color(9.0/255.0,15.0/255.0,17.0/255.0,0.97)
		TILE_BG=Color("0e181b");ROW_BG=Color("0c1518");ACTIVE_BG=Color("16222a");HOVER_BG=Color("111c1f");CLOSE_HOVER_BG=Color("1a2427");BUTTON_BG=Color("131d20");FIELD_BG=Color("0a1214");SPEED_IDLE_BG=Color("0d1719");TRACK=Color("1b2528");TOOLBAR_BG=Color("080d0feb");MAP_LABEL_BG=Color("060a0bbf")
		BORDER=Color("2a3538");BORDER_2=Color("2f3b3e");BORDER_SOFT=Color("223034");LAYER_ON_BORDER=Color("7ca39d")
		INK=Color("f0e6d1");BODY=Color("e4dfd2");BODY_2=Color("d8d3c6");TEXT_SOFT=Color("b6bdb7");TEXT_DIM=Color("a9b0ab");MUTED=Color("8a948f");DISABLED=Color("6f7a77");LAYER_ON_FG=Color("d7d0bf")
		GOLD=Color("c9a95a");GOLD_BRIGHT=Color("ead078");GOLD_WASH=Color(201.0/255.0,169.0/255.0,90.0/255.0,0.12);GREEN=Color("8fa26a");RED=Color("c67462");AMBER=Color("d0b46f");TEAL=Color("79a8a0");BLUE=Color("8798b5");VIOLET=Color("a897c9");GLYPH_DARK=Color("0d1416")
		WARN_BG=Color(201.0/255.0,169.0/255.0,90.0/255.0,0.08);WARN_BORDER=Color("7d6a3a");DANGER_BG=Color(198.0/255.0,116.0/255.0,98.0/255.0,0.12);DANGER_BORDER=Color("8a4f44");INFO_BG=Color(121.0/255.0,168.0/255.0,160.0/255.0,0.10);INFO_BORDER=Color("3e5f5a")
	else:
		PANEL_BG=Color("f3efe6f0");PANEL_BG_SOLID=Color("f6f2e9f8");DOCK_BG=Color("f7f3eafa");TILE_BG=Color("eae4d8");ROW_BG=Color("f0ebe1");ACTIVE_BG=Color("ded6c7");HOVER_BG=Color("e6dfd2");CLOSE_HOVER_BG=Color("ead8d1");BUTTON_BG=Color("e9e2d5");FIELD_BG=Color("fbf8f0");SPEED_IDLE_BG=Color("ece6da");TRACK=Color("d5cdbf");TOOLBAR_BG=Color("f5f1e8ed");MAP_LABEL_BG=Color("f7f3ead9")
		BORDER=Color("aaa08e");BORDER_2=Color("988e7d");BORDER_SOFT=Color("c6bdad");LAYER_ON_BORDER=Color("537d76");INK=Color("252a28");BODY=Color("353b38");BODY_2=Color("464c48");TEXT_SOFT=Color("59625d");TEXT_DIM=Color("66706a");MUTED=Color("737d77");DISABLED=Color("929a95");LAYER_ON_FG=Color("343b37")
		GOLD=Color("8d6c20");GOLD_BRIGHT=Color("6e5214");GOLD_WASH=Color(141.0/255.0,108.0/255.0,32.0/255.0,0.12);GREEN=Color("647a3e");RED=Color("a64f40");AMBER=Color("8c6d28");TEAL=Color("427c73");BLUE=Color("596d91");VIOLET=Color("735f92");GLYPH_DARK=Color("f4efe5")
		WARN_BG=Color(141.0/255.0,108.0/255.0,32.0/255.0,0.10);WARN_BORDER=Color("8d6c20");DANGER_BG=Color(166.0/255.0,79.0/255.0,64.0/255.0,0.10);DANGER_BORDER=Color("a64f40");INFO_BG=Color(66.0/255.0,124.0/255.0,115.0/255.0,0.10);INFO_BORDER=Color("427c73")

static func is_light()->bool:return color_mode=="light"

static func control_theme()->Theme:
	if _control_theme:return _control_theme
	var result:=Theme.new()
	for type_name:String in ["Label","Button","OptionButton","CheckBox","LineEdit","RichTextLabel"]:
		result.set_color("font_color",type_name,BODY)
		result.set_color("font_hover_color",type_name,INK)
		result.set_color("font_focus_color",type_name,INK)
		result.set_color("font_pressed_color",type_name,INK)
		result.set_color("font_disabled_color",type_name,DISABLED)
	result.set_color("default_color","RichTextLabel",BODY)
	result.set_color("font_placeholder_color","LineEdit",MUTED)
	for type_name:String in ["Button","OptionButton"]:
		result.set_stylebox("normal",type_name,action_button_style(false))
		result.set_stylebox("hover",type_name,action_button_style(false,true))
		result.set_stylebox("pressed",type_name,action_button_style(true))
		result.set_stylebox("focus",type_name,gold_outline_style())
	result.set_stylebox("normal","LineEdit",flat(FIELD_BG,BORDER,1,3,8))
	result.set_stylebox("focus","LineEdit",flat(FIELD_BG,GOLD,1,3,8))
	result.set_stylebox("background","ProgressBar",flat(TRACK))
	result.set_color("font_color","ProgressBar",BODY)
	_control_theme=result
	return result

static func surface(dark_color:Color,light_color:Color=Color("f0ebe1"))->Color:
	if not is_light():return dark_color
	var result:=light_color;result.a=dark_color.a
	return result

# Cohort colors (age structure, in order 0-4 .. 60+)
const COHORT_COLORS:Array[Color]=[Color("#9b7252"),Color("#779a67"),Color("#5e9d70"),Color("#4f916d"),Color("#6f8f65"),Color("#766d72")]
# Labor role colors, Sustenance..Watch
const ROLE_COLORS:Array[Color]=[Color("#8fa26a"),Color("#79a8a0"),Color("#a9946e"),Color("#b39a68"),Color("#c9a95a"),Color("#8798b5"),Color("#a897c9"),Color("#d0b46f"),Color("#c67462")]

# Layout
const RAIL_WIDTH:=84.0
const RAIL_BUTTON_HEIGHT:=62.0
const RAIL_HEADER_HEIGHT:=44.0
const DOCK_X:=96.0
const DOCK_WIDTH:=540.0
const DOCK_DETAIL_X:=652.0
const DOCK_MARGIN_Y:=14.0
const EDGE_MARGIN:=16.0
const CHIP_HEIGHT:=44.0
const QUEUE_WIDTH:=400.0

static func delta_color(direction:int,attention:bool=false)->Color:
	## improving > 0, worsening < 0, neutral 0; attention overrides neutral.
	if direction>0: return GREEN
	if direction<0: return RED
	return AMBER if attention else MUTED

static func capacity_color(value:float)->Color:
	if value<40.0: return RED
	if value<60.0: return AMBER
	return GREEN

static func flat(bg:Color,border:Color=Color(0,0,0,0),border_width:int=0,radius:int=0,pad:float=0.0)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	# Older HUD cards still supply their established dark neutral directly. In
	# light mode, translate only those near-black surfaces; accents stay intact.
	var luminance:=bg.r*.2126+bg.g*.7152+bg.b*.0722
	style.bg_color=surface(bg) if is_light() and bg.a>0.0 and luminance<.16 else bg
	if border_width>0:
		style.border_color=border
		style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

static func panel_style()->StyleBoxFlat:
	return flat(PANEL_BG,BORDER,1,4)

static func dock_style()->StyleBoxFlat:
	return flat(DOCK_BG,BORDER,1,4)

static func chip_style(hover:bool=false)->StyleBoxFlat:
	var style:=flat(PANEL_BG,GOLD if hover else BORDER,1,4)
	style.content_margin_left=12.0
	style.content_margin_right=12.0
	return style

static func rail_button_style(active:bool,hover:bool=false)->StyleBoxFlat:
	var style:=flat(ACTIVE_BG if active else Color(0,0,0,0),GOLD if (active or hover) else BORDER_2,1,4)
	return style

static func tile_style(accent:Color=Color(0,0,0,0))->StyleBoxFlat:
	var style:=flat(TILE_BG,Color(0,0,0,0),0,4)
	style.content_margin_left=9.0
	style.content_margin_right=9.0
	style.content_margin_top=7.0
	style.content_margin_bottom=7.0
	if accent.a>0.0:
		style.border_color=accent
		style.border_width_bottom=2
	return style

static func row_style(accent:Color=Color(0,0,0,0))->StyleBoxFlat:
	var style:=flat(ROW_BG,Color(0,0,0,0),0,3)
	style.content_margin_left=10.0
	style.content_margin_right=10.0
	style.content_margin_top=7.0
	style.content_margin_bottom=7.0
	if accent.a>0.0:
		style.border_color=accent
		style.border_width_left=2
	return style

static func action_button_style(primary:bool,hover:bool=false)->StyleBoxFlat:
	var border:=GOLD if (primary or hover) else BORDER_2
	var style:=flat(BUTTON_BG,border,1,3)
	style.content_margin_left=12.0
	style.content_margin_right=12.0
	return style

static func gold_outline_style()->StyleBoxFlat:
	var style:=flat(GOLD_WASH,GOLD,1,3)
	style.content_margin_left=10.0
	style.content_margin_right=10.0
	return style

static func brief_style(tone:String)->StyleBoxFlat:
	var bg:=INFO_BG
	var border:=INFO_BORDER
	match tone:
		"warn": bg=WARN_BG; border=WARN_BORDER
		"danger": bg=DANGER_BG; border=DANGER_BORDER
	var style:=flat(bg,border,1,4)
	style.content_margin_left=11.0
	style.content_margin_right=11.0
	style.content_margin_top=9.0
	style.content_margin_bottom=9.0
	return style

static func pill_style()->StyleBoxFlat:
	var style:=flat(PANEL_BG,BORDER,1,22)
	return style

static var _spaced_fonts:Dictionary={}

static func style_label(label:Label,size:int,color:Color,spacing_em:float=0.0)->Label:
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	if spacing_em>0.0:
		label.add_theme_font_override("font",_spaced_font(int(round(size*spacing_em*10.0))))
	return label

static func _spaced_font(tenth_px:int)->FontVariation:
	## Letter-spacing approximation: FontVariation with per-glyph spacing.
	if _spaced_fonts.has(tenth_px): return _spaced_fonts[tenth_px]
	var variation:=FontVariation.new()
	variation.base_font=ThemeDB.fallback_font
	variation.spacing_glyph=maxi(1,int(round(tenth_px/10.0)))
	_spaced_fonts[tenth_px]=variation
	return variation

static func make_label(text:String,size:int,color:Color,spacing_em:float=0.0)->Label:
	var label:=Label.new()
	label.text=text
	return style_label(label,size,color,spacing_em)
