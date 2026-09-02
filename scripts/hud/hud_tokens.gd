class_name HudTokens
## Design tokens for the Command Rail HUD (design resolution 1920x1080).
## Source: design_handoff_command_rail_hud/README.md — values are final.

# Backgrounds
const PANEL_BG:=Color(8.0/255.0,13.0/255.0,15.0/255.0,0.94)
const PANEL_BG_SOLID:=Color(8.0/255.0,13.0/255.0,15.0/255.0,0.97)
const DOCK_BG:=Color(9.0/255.0,15.0/255.0,17.0/255.0,0.97)
const TILE_BG:=Color("#0e181b")
const ROW_BG:=Color("#0c1518")
const ACTIVE_BG:=Color("#16222a")
const HOVER_BG:=Color("#111c1f")
const CLOSE_HOVER_BG:=Color("#1a2427")
const BUTTON_BG:=Color("#131d20")
const FIELD_BG:=Color("#0a1214")
const SPEED_IDLE_BG:=Color("#0d1719")
const TRACK:=Color("#1b2528")
const TOOLBAR_BG:=Color(8.0/255.0,13.0/255.0,15.0/255.0,0.92)
const MAP_LABEL_BG:=Color(6.0/255.0,10.0/255.0,11.0/255.0,0.75)

# Borders
const BORDER:=Color("#2a3538")
const BORDER_2:=Color("#2f3b3e")
const BORDER_SOFT:=Color("#223034")
const LAYER_ON_BORDER:=Color("#7ca39d")

# Text
const INK:=Color("#f0e6d1")
const BODY:=Color("#e4dfd2")
const BODY_2:=Color("#d8d3c6")
const TEXT_SOFT:=Color("#b6bdb7")
const TEXT_DIM:=Color("#a9b0ab")
const MUTED:=Color("#8a948f")
const DISABLED:=Color("#6f7a77")
const LAYER_ON_FG:=Color("#d7d0bf")

# Accents
const GOLD:=Color("#c9a95a")
const GOLD_BRIGHT:=Color("#ead078")
const GOLD_WASH:=Color(201.0/255.0,169.0/255.0,90.0/255.0,0.12)
const GREEN:=Color("#8fa26a")
const RED:=Color("#c67462")
const AMBER:=Color("#d0b46f")
const TEAL:=Color("#79a8a0")
const BLUE:=Color("#8798b5")
const VIOLET:=Color("#a897c9")
const DARK_INK:=Color("#111111")
const GLYPH_DARK:=Color("#0d1416")

# Brief tones
const WARN_BG:=Color(201.0/255.0,169.0/255.0,90.0/255.0,0.08)
const WARN_BORDER:=Color("#7d6a3a")
const DANGER_BG:=Color(198.0/255.0,116.0/255.0,98.0/255.0,0.12)
const DANGER_BORDER:=Color("#8a4f44")
const INFO_BG:=Color(121.0/255.0,168.0/255.0,160.0/255.0,0.10)
const INFO_BORDER:=Color("#3e5f5a")

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
	style.bg_color=bg
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
