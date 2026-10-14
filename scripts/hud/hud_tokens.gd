class_name HudTokens
## Design tokens for the Command Rail HUD (design resolution 1920x1080).
## Modern Strategy: docs/design/MODERN_STRATEGY.md. Compatibility token names
## remain stable so presentation changes do not touch simulation or saved state.

# Runtime palette. DisplayPreferences sets it before the HUD is constructed.
static var color_mode:="dark"
static var PANEL_BG:=Color("111e28")
static var PANEL_BG_SOLID:=Color("111e28")
static var DOCK_BG:=Color("111e28")
static var TILE_BG:=Color("1b303a")
static var ROW_BG:=Color("182b35")
static var ACTIVE_BG:=Color("263f49")
static var HOVER_BG:=Color("223943")
static var CLOSE_HOVER_BG:=Color("343741")
static var BUTTON_BG:=Color("162932")
static var FIELD_BG:=Color("0e1a23")
static var SPEED_IDLE_BG:=Color("182b35")
static var TRACK:=Color("3c5058")
static var TOOLBAR_BG:=Color("111e28f5")
static var MAP_LABEL_BG:=Color("111e28ed")
static var BORDER:=Color("3c5058")
static var BORDER_2:=Color("60727a")
static var BORDER_SOFT:=Color("314650")
static var LAYER_ON_BORDER:=Color("f38665")
static var INK:=Color("f4eee0")
static var BODY:=Color("e4e9e5")
static var BODY_2:=Color("ccd7d6")
static var TEXT_SOFT:=Color("b7c5c7")
static var TEXT_DIM:=Color("b7c5c7")
static var MUTED:=Color("b7c5c7")
static var DISABLED:=Color("94a4aa")
static var LAYER_ON_FG:=Color("f4eee0")
static var GOLD:=Color("f38665")
static var GOLD_BRIGHT:=Color("ffad8f")
static var GOLD_WASH:=Color("f3866520")
static var GREEN:=Color("9bc59c")
static var RED:=Color("f29b9f")
static var AMBER:=Color("eac17a")
static var TEAL:=Color("8ed2c1")
static var BLUE:=Color("a5c9f4")
static var VIOLET:=Color("c7b5ea")
## Text-safe accents. The plain accents above are for bars, rules, stripes and
## icons; they fall near 3.3:1 on paper. Any accent that colours TEXT uses its
## *_TEXT twin, which reads at 4.5:1 or better on every paper ground (PANEL_BG,
## DOCK_BG, TILE_BG, ROW_BG, PAPER, PAPER_RAISED, PAPER_SUNK, ACTIVE_BG) in
## light mode and on every night ground in dark mode. tests/test_button_contrast.gd
## checks each pair. text_for(accent) maps an accent to its twin.
static var GREEN_TEXT:=Color("b5d7b5")
static var RED_TEXT:=Color("ffb4b7")
static var AMBER_TEXT:=Color("f1d397")
static var TEAL_TEXT:=Color("a6dfd1")
static var BLUE_TEXT:=Color("b8d8ff")
static var VIOLET_TEXT:=Color("d7c8f4")
static var GOLD_TEXT:=Color("ffb69e")
static var DARK_INK:=Color("14232b")
static var GLYPH_DARK:=Color("111e28")
static var WARN_BG:=Color("eac17a14")
static var WARN_BORDER:=Color("eac17a")
static var DANGER_BG:=Color("f29b9f16")
static var DANGER_BORDER:=Color("f29b9f")
static var INFO_BG:=Color("8ed2c114")
static var INFO_BORDER:=Color("8ed2c1")
static var ACTION:=Color("f38665")
static var ACTION_INK:=Color("14232b")
static var _control_theme:Theme

# --- Chronicle type and chrome (docs/ART_DIRECTION.md section 2) -----------
# Three bundled faces and no SystemFont lookups: Cinzel for titles, EB Garamond
# for voices and quotes, Barlow for the interface.
const FONT_DISPLAY:=preload("res://assets/fonts/cinzel/Cinzel.ttf")
const FONT_UI:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
const FONT_VOICE_PATH:="res://assets/fonts/serif/EBGaramond.ttf"
const FONT_VOICE_ITALIC_PATH:="res://assets/fonts/serif/EBGaramond-Italic.ttf"

# Loaded at run time, not preloaded: a fresh checkout imports the new font files
# during the same scan that compiles this script.
static func _voice_file(italic:bool=false)->Font:
	var path:=FONT_VOICE_ITALIC_PATH if italic else FONT_VOICE_PATH
	return load(path) as Font if ResourceLoader.exists(path) else FONT_UI
const MIN_FONT_SIZE:=12
const SPACE:=[0,4,8,12,16,24,32,48]
const RADIUS_CONTROL:=4
const RADIUS_CARD:=8
const MOTION:={"fast":0.12,"base":0.20,"slow":0.36,"scene":0.90}
## Role -> [face, size]. Faces: "display", "voice", "voice_italic", "ui", "ui_strong".
const TYPE:={"display":["ui_strong",38],"title":["ui_strong",32],"voice":["voice",22],
	"voice_small":["voice",18],"value":["ui_strong",28],"body":["ui",16],"small":["ui",14],"kicker":["ui_strong",12]}
## Chrome palette: one paper language for the rail, panels and scene headers.
static var PAPER:=Color("111e28")
static var PAPER_RAISED:=Color("1b303a")
static var PAPER_SUNK:=Color("0e1a23")
static var RULE:=Color("3c5058")
static var RULE_STRONG:=Color("60727a")
static var INK_MUTED:=Color("b7c5c7")
static var SCRIM:=Color("060e16b8")
static var _fonts:Dictionary={}

static func font(face:String)->Font:
	## Shared font resources, one per face; never a SystemFont.
	if _fonts.has(face):return _fonts[face]
	var result:Font
	match face:
		"display":result=font("ui_strong")
		"voice":result=_voice_file()
		"voice_italic":result=_voice_file(true)
		"voice_bold":
			var bold:=FontVariation.new();bold.base_font=_voice_file();bold.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):600};result=bold
		"ui_strong":
			var strong:=FontVariation.new();strong.base_font=FONT_UI;strong.variation_embolden=0.35;result=strong
		_:result=FONT_UI
	_fonts[face]=result
	return result

static func voice_font(italic:bool=false)->Font:return font("voice_italic" if italic else "voice")

static func text(control:Control,role:String,color:Color=Color(0,0,0,0))->Control:
	## The one way to size text: face and size come from the TYPE scale.
	var spec:Array=TYPE.get(role,TYPE.body)
	control.add_theme_font_override("normal_font" if control is RichTextLabel else "font",font(String(spec[0])))
	control.add_theme_font_size_override("normal_font_size" if control is RichTextLabel else "font_size",maxi(MIN_FONT_SIZE,int(spec[1])))
	if color.a>0.0:control.add_theme_color_override("default_color" if control is RichTextLabel else "font_color",color)
	return control

static func paper_panel_style(raised:bool=false,radius:int=RADIUS_CARD,pad:float=0.0)->StyleBoxFlat:
	## Opaque paper chrome with a 1 px rule. Never see-through.
	var style:=StyleBoxFlat.new()
	style.bg_color=PAPER_RAISED if raised else PAPER
	style.border_color=RULE
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	return style

static func install_global_fonts()->void:
	## Everything that asks ThemeDB for a font (custom draw code, dialogs,
	## tooltips outside the HUD) gets Barlow instead of the engine fallback.
	ThemeDB.fallback_font=FONT_UI
	ThemeDB.fallback_font_size=16

static func set_color_mode(mode:String)->void:
	color_mode="light" if mode=="light" else "dark"
	_control_theme=null
	if is_light():
		PANEL_BG=Color("f2f5f5")
		PANEL_BG_SOLID=Color("f2f5f5")
		DOCK_BG=Color("f2f5f5")
		TILE_BG=Color("e7eeee")
		ROW_BG=Color("eaf0f0")
		ACTIVE_BG=Color("dce5e7")
		HOVER_BG=Color("e0e9eb")
		CLOSE_HOVER_BG=Color("f0dddd")
		BUTTON_BG=Color("edf2f2")
		FIELD_BG=Color("ffffff")
		SPEED_IDLE_BG=Color("e7eeee")
		TRACK=Color("c0cfd3")
		TOOLBAR_BG=Color("f2f5f5f5")
		MAP_LABEL_BG=Color("f2f5f5ed")
		BORDER=Color("c0cfd3")
		BORDER_2=Color("8b9da4")
		BORDER_SOFT=Color("ccd7da")
		LAYER_ON_BORDER=Color("a43a24")
		INK=Color("142b34")
		BODY=Color("213b45")
		BODY_2=Color("354c54")
		TEXT_SOFT=Color("4e626a")
		TEXT_DIM=Color("4e626a")
		MUTED=Color("4e626a")
		DISABLED=Color("677d85")
		LAYER_ON_FG=Color("142b34")
		GOLD=Color("b7442c")
		GOLD_BRIGHT=Color("8d2e1d")
		GREEN=Color("3b704b")
		RED=Color("b5444c")
		AMBER=Color("916316")
		TEAL=Color("277568")
		BLUE=Color("396c9e")
		VIOLET=Color("72559b")
		GREEN_TEXT=Color("31563c")
		RED_TEXT=Color("883039")
		AMBER_TEXT=Color("684810")
		TEAL_TEXT=Color("22584f")
		BLUE_TEXT=Color("31567a")
		VIOLET_TEXT=Color("594077")
		GOLD_TEXT=Color("87301f")
		DARK_INK=Color("14232b")
		GLYPH_DARK=Color("f2f5f5")
		WARN_BORDER=Color("916316")
		DANGER_BORDER=Color("b5444c")
		INFO_BORDER=Color("277568")
		PAPER=Color("f2f5f5")
		PAPER_RAISED=Color("ffffff")
		PAPER_SUNK=Color("e7eeee")
		RULE=Color("c0cfd3")
		RULE_STRONG=Color("8b9da4")
		INK_MUTED=Color("4e626a")
		GOLD_WASH=Color("b7442c16")
		WARN_BG=Color("91631612")
		DANGER_BG=Color("b5444c12")
		INFO_BG=Color("27756812")
		SCRIM=Color("10252b70")
		ACTION=Color("b7442c")
		ACTION_INK=Color("fff9ef")
	else:
		PANEL_BG=Color("111e28")
		PANEL_BG_SOLID=Color("111e28")
		DOCK_BG=Color("111e28")
		TILE_BG=Color("1b303a")
		ROW_BG=Color("182b35")
		ACTIVE_BG=Color("263f49")
		HOVER_BG=Color("223943")
		CLOSE_HOVER_BG=Color("343741")
		BUTTON_BG=Color("162932")
		FIELD_BG=Color("0e1a23")
		SPEED_IDLE_BG=Color("182b35")
		TRACK=Color("3c5058")
		TOOLBAR_BG=Color("111e28f5")
		MAP_LABEL_BG=Color("111e28ed")
		BORDER=Color("3c5058")
		BORDER_2=Color("60727a")
		BORDER_SOFT=Color("314650")
		LAYER_ON_BORDER=Color("f38665")
		INK=Color("f4eee0")
		BODY=Color("e4e9e5")
		BODY_2=Color("ccd7d6")
		TEXT_SOFT=Color("b7c5c7")
		TEXT_DIM=Color("b7c5c7")
		MUTED=Color("b7c5c7")
		DISABLED=Color("94a4aa")
		LAYER_ON_FG=Color("f4eee0")
		GOLD=Color("f38665")
		GOLD_BRIGHT=Color("ffad8f")
		GREEN=Color("9bc59c")
		RED=Color("f29b9f")
		AMBER=Color("eac17a")
		TEAL=Color("8ed2c1")
		BLUE=Color("a5c9f4")
		VIOLET=Color("c7b5ea")
		GREEN_TEXT=Color("b5d7b5")
		RED_TEXT=Color("ffb4b7")
		AMBER_TEXT=Color("f1d397")
		TEAL_TEXT=Color("a6dfd1")
		BLUE_TEXT=Color("b8d8ff")
		VIOLET_TEXT=Color("d7c8f4")
		GOLD_TEXT=Color("ffb69e")
		DARK_INK=Color("14232b")
		GLYPH_DARK=Color("111e28")
		WARN_BORDER=Color("eac17a")
		DANGER_BORDER=Color("f29b9f")
		INFO_BORDER=Color("8ed2c1")
		PAPER=Color("111e28")
		PAPER_RAISED=Color("1b303a")
		PAPER_SUNK=Color("0e1a23")
		RULE=Color("3c5058")
		RULE_STRONG=Color("60727a")
		INK_MUTED=Color("b7c5c7")
		GOLD_WASH=Color("f3866520")
		WARN_BG=Color("eac17a14")
		DANGER_BG=Color("f29b9f16")
		INFO_BG=Color("8ed2c114")
		SCRIM=Color("060e16b8")
		ACTION=Color("f38665")
		ACTION_INK=Color("14232b")

static func is_light()->bool:return color_mode=="light"

## The grounds text sits on, for the current palette. Contrast tests and
## legible() judge text against every one of them.
static func text_grounds()->Array[Color]:
	return [PANEL_BG,PANEL_BG_SOLID,DOCK_BG,TILE_BG,ROW_BG,HOVER_BG,BUTTON_BG,FIELD_BG,ACTIVE_BG,PAPER,PAPER_RAISED,PAPER_SUNK]

## The text twin of an accent: GREEN -> GREEN_TEXT and so on. Colours that are
## already text colours come back unchanged; any other colour is darkened (or
## lightened at night) until it reads on TILE_BG.
static func text_for(accent:Color)->Color:
	if accent==GREEN or accent==GREEN_TEXT:return GREEN_TEXT
	if accent==RED or accent==DANGER_BORDER or accent==RED_TEXT:return RED_TEXT
	if accent==AMBER or accent==WARN_BORDER or accent==AMBER_TEXT:return AMBER_TEXT
	if accent==TEAL or accent==INFO_BORDER or accent==TEAL_TEXT:return TEAL_TEXT
	if accent==BLUE or accent==BLUE_TEXT:return BLUE_TEXT
	if accent==VIOLET or accent==VIOLET_TEXT:return VIOLET_TEXT
	if accent==GOLD or accent==GOLD_TEXT:return GOLD_TEXT
	return legible(accent)

## WCAG relative luminance and contrast ratio (sRGB colours).
static func relative_luminance(color:Color)->float:
	var channels:=[color.r,color.g,color.b]
	for i in 3:channels[i]=channels[i]/12.92 if channels[i]<=0.03928 else pow((channels[i]+0.055)/1.055,2.4)
	return 0.2126*channels[0]+0.7152*channels[1]+0.0722*channels[2]

static func contrast(a:Color,b:Color)->float:
	var high:=maxf(relative_luminance(a),relative_luminance(b));var low:=minf(relative_luminance(a),relative_luminance(b))
	return (high+0.05)/(low+0.05)

## Any colour made readable as text: on the given ground, or on every paper
## ground of the current palette when none is given. Keeps the hue and only
## moves lightness toward ink (light grounds) or toward cream (night grounds).
static func legible(color:Color,ground:Color=Color(0,0,0,0),ratio:float=4.5)->Color:
	var grounds:Array[Color]=text_grounds()
	if ground.a>0.0:grounds=[ground]
	var result:=Color(color.r,color.g,color.b,1.0)
	var toward_dark:=relative_luminance(grounds[0])>0.18
	for step in 60:
		var worst:=INF
		for bg:Color in grounds:worst=minf(worst,contrast(result,bg))
		if worst>=ratio:break
		result=result.darkened(0.05) if toward_dark else result.lightened(0.05)
	result.a=color.a
	return result

## Sentence case for labels that arrive shouted from older code or data:
## "SEND THE CARAVAN" -> "Send the caravan". Mixed-case text is left alone, so
## names and deliberate capitals survive. Only 12 px kickers may stay in caps.
static func sentence_case(value:String)->String:
	if value!=value.to_upper() or value==value.to_lower():return value
	var lowered:=value.to_lower()
	for position in lowered.length():
		if lowered[position]!=lowered[position].to_upper():
			return lowered.substr(0,position)+lowered[position].to_upper()+lowered.substr(position+1)
	return lowered

static func control_theme()->Theme:
	if _control_theme:return _control_theme
	var result:=Theme.new()
	result.default_font=FONT_UI
	result.default_font_size=16
	for type_name:String in ["Label","Button","OptionButton","CheckBox","CheckButton","LineEdit","RichTextLabel","PopupMenu"]:
		result.set_color("font_color",type_name,BODY)
		result.set_color("font_hover_color",type_name,INK)
		result.set_color("font_focus_color",type_name,INK)
		result.set_color("font_pressed_color",type_name,INK)
		result.set_color("font_disabled_color",type_name,DISABLED)
	result.set_color("default_color","RichTextLabel",BODY)
	result.set_color("font_placeholder_color","LineEdit",MUTED)
	result.set_color("font_selected_color","LineEdit",INK)
	result.set_color("selection_color","LineEdit",ACTIVE_BG)
	result.set_color("caret_color","LineEdit",INK)
	result.set_stylebox("panel","PopupMenu",flat(PANEL_BG_SOLID,BORDER,1,3,6))
	result.set_stylebox("hover","PopupMenu",flat(HOVER_BG))
	result.set_stylebox("panel","AcceptDialog",flat(PANEL_BG_SOLID,BORDER,1,4,12))
	result.set_color("title_color","Window",INK)
	result.set_color("title_outline_modulate","Window",Color.TRANSPARENT)
	result.set_stylebox("embedded_border","Window",flat(PANEL_BG_SOLID,BORDER,1,4,8))
	for type_name:String in ["Button","OptionButton"]:
		result.set_stylebox("normal",type_name,action_button_style(false))
		result.set_stylebox("hover",type_name,action_button_style(false,true))
		result.set_stylebox("pressed",type_name,button_pressed_style())
		result.set_stylebox("hover_pressed",type_name,button_pressed_style())
		result.set_stylebox("disabled",type_name,button_disabled_style())
		result.set_stylebox("focus",type_name,gold_outline_style())
		result.set_color("font_hover_pressed_color",type_name,INK)
	result.set_stylebox("normal","LineEdit",flat(FIELD_BG,BORDER,1,3,8))
	result.set_stylebox("focus","LineEdit",flat(FIELD_BG,GOLD,1,3,8))
	result.set_stylebox("background","ProgressBar",flat(TRACK))
	result.set_color("font_color","ProgressBar",BODY)
	add_tooltip_style(result)
	_control_theme=result
	return result

## Hover clues. Godot draws every tooltip as a TooltipPanel popup holding a
## TooltipLabel, parented to the hovered control, so it inherits that control's
## theme: a theme that colours "Label" but not "TooltipLabel" puts HUD ink on
## Godot's default dark tooltip panel. Any theme that sets Label colours must
## also carry these (paper and ink in light mode, dark panel and light text in
## dark mode). The root window carries control_theme(), which covers
## everything outside the HUD tree.
const TOOLTIP_MAX_WIDTH:=440.0
const TOOLTIP_FONT_SIZE:=15

static func tooltip_panel_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=PAPER_RAISED
	style.border_color=BORDER_2 if is_light() else Color("56686b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left=12.0
	style.content_margin_right=12.0
	style.content_margin_top=8.0
	style.content_margin_bottom=8.0
	style.shadow_color=Color(0,0,0,0.22 if is_light() else 0.45)
	style.shadow_size=6
	style.shadow_offset=Vector2(0,2)
	return style

static func add_tooltip_style(theme:Theme)->void:
	theme.set_type_variation("TooltipPanel","PopupPanel")
	theme.set_type_variation("TooltipLabel","Label")
	theme.set_stylebox("panel","TooltipPanel",tooltip_panel_style())
	theme.set_color("font_color","TooltipLabel",INK)
	theme.set_color("font_shadow_color","TooltipLabel",Color(0,0,0,0))
	theme.set_color("font_outline_color","TooltipLabel",Color(0,0,0,0))
	theme.set_constant("outline_size","TooltipLabel",0)
	theme.set_constant("shadow_offset_x","TooltipLabel",0)
	theme.set_constant("shadow_offset_y","TooltipLabel",0)
	theme.set_constant("line_spacing","TooltipLabel",3)
	theme.set_font_size("font_size","TooltipLabel",TOOLTIP_FONT_SIZE)

static func shape_tooltip(label:Label)->void:
	## Wraps a long plain tooltip at a readable width instead of one long line.
	if label.text.is_empty(): return
	var font:=label.get_theme_font("font")
	var font_size:=label.get_theme_font_size("font_size")
	if font==null: return
	var width:=font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1.0,font_size).x
	if width<=TOOLTIP_MAX_WIDTH: return
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x=TOOLTIP_MAX_WIDTH

static func tooltip_node_added(node:Node)->void:
	if node is Label and (node as Label).theme_type_variation==&"TooltipLabel": shape_tooltip(node as Label)

static func surface(dark_color:Color,light_color:Color=Color("e8dece"))->Color:
	if not is_light():return dark_color
	var result:=light_color;result.a=dark_color.a
	return result

# Cohort colors (age structure, in order 0-4 .. 60+)
const COHORT_COLORS:Array[Color]=[Color("#9b7252"),Color("#779a67"),Color("#5e9d70"),Color("#4f916d"),Color("#6f8f65"),Color("#766d72")]
# Labor role colors, Sustenance..Watch
const ROLE_COLORS:Array[Color]=[Color("#8fa26a"),Color("#79a8a0"),Color("#a9946e"),Color("#b39a68"),Color("#c9a95a"),Color("#8798b5"),Color("#a897c9"),Color("#d0b46f"),Color("#c67462")]

# Layout
const RAIL_WIDTH:=132.0
const RAIL_BUTTON_HEIGHT:=46.0
const RAIL_HEADER_HEIGHT:=42.0
const TOP_BAR_HEIGHT:=72.0
const CONTENT_TOP:=TOP_BAR_HEIGHT+8.0
const DOCK_X:=RAIL_WIDTH+10.0
const DOCK_WIDTH:=540.0
const DOCK_DETAIL_X:=DOCK_X+DOCK_WIDTH+24.0
const DOCK_MARGIN_Y:=8.0
const EDGE_MARGIN:=10.0
const CHIP_HEIGHT:=40.0

static func delta_color(direction:int,attention:bool=false)->Color:
	## improving > 0, worsening < 0, neutral 0; attention overrides neutral.
	if direction>0: return GREEN
	if direction<0: return RED
	return AMBER if attention else MUTED

## delta_color() for text: the same meaning in the readable twins.
static func delta_text_color(direction:int,attention:bool=false)->Color:
	if direction>0: return GREEN_TEXT
	if direction<0: return RED_TEXT
	return AMBER_TEXT if attention else MUTED

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
	if is_light():
		var light_style:=flat(ACTIVE_BG if active else HOVER_BG if hover else Color.TRANSPARENT)
		if active or hover:
			light_style.border_color=GOLD if active else BORDER_2
			light_style.border_width_left=3 if active else 2
		light_style.set_corner_radius_all(2)
		return light_style
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
	var hover_action:=ACTION.darkened(0.08) if is_light() else ACTION.lightened(0.08)
	var fill:=hover_action if primary and hover else ACTION if primary else HOVER_BG if hover else BUTTON_BG
	var style:=flat(fill,ACTION if primary else BORDER_2 if hover else BORDER,0 if primary else 1,RADIUS_CONTROL)
	style.content_margin_left=16.0;style.content_margin_right=16.0
	style.content_margin_top=8.0;style.content_margin_bottom=8.0
	return style

static func button_pressed_style()->StyleBoxFlat:
	var style:=flat(ACTIVE_BG,ACTION,1,RADIUS_CONTROL)
	style.content_margin_left=16.0;style.content_margin_right=16.0
	style.content_margin_top=8.0;style.content_margin_bottom=8.0
	return style

static func button_disabled_style()->StyleBoxFlat:
	return flat(PAPER_SUNK,BORDER_SOFT,1,RADIUS_CONTROL,8)

static func gold_outline_style()->StyleBoxFlat:
	# Compatibility name: keyboard focus is now the shared coral accent.
	return flat(Color.TRANSPARENT,ACTION,2,RADIUS_CONTROL,8)

static func apply_button_style(button:Button,primary:bool=false)->Button:
	button.set_meta("modern_primary",primary)
	button.custom_minimum_size.y=maxf(button.custom_minimum_size.y,44 if primary else 40)
	button.add_theme_font_override("font",font("ui_strong") if primary else FONT_UI)
	button.add_theme_font_size_override("font_size",16 if primary else 14)
	button.add_theme_stylebox_override("normal",action_button_style(primary))
	button.add_theme_stylebox_override("hover",action_button_style(primary,true))
	button.add_theme_stylebox_override("pressed",button_pressed_style())
	button.add_theme_stylebox_override("hover_pressed",button_pressed_style())
	button.add_theme_stylebox_override("disabled",button_disabled_style())
	button.add_theme_stylebox_override("focus",gold_outline_style())
	button.add_theme_color_override("font_color",ACTION_INK if primary else INK)
	button.add_theme_color_override("font_hover_color",ACTION_INK if primary else INK)
	button.add_theme_color_override("font_focus_color",ACTION_INK if primary else INK)
	button.add_theme_color_override("font_pressed_color",INK)
	button.add_theme_color_override("font_hover_pressed_color",INK)
	button.add_theme_color_override("font_disabled_color",DISABLED)
	return button

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
	var style:=flat(PANEL_BG,BORDER_SOFT,1,8)
	return style

static var _spaced_fonts:Dictionary={}

static func style_label(label:Label,size:int,color:Color,spacing_em:float=0.0)->Label:
	label.add_theme_font_size_override("font_size",maxi(MIN_FONT_SIZE,size))
	label.add_theme_color_override("font_color",color)
	if spacing_em>0.0:
		label.add_theme_font_override("font",_spaced_font(int(round(size*spacing_em*10.0))))
	return label

static func _spaced_font(tenth_px:int)->FontVariation:
	## Letter-spacing approximation: FontVariation with per-glyph spacing.
	if _spaced_fonts.has(tenth_px): return _spaced_fonts[tenth_px]
	var variation:=FontVariation.new()
	variation.base_font=FONT_UI
	variation.spacing_glyph=maxi(1,int(round(tenth_px/10.0)))
	_spaced_fonts[tenth_px]=variation
	return variation

static func make_label(text:String,size:int,color:Color,spacing_em:float=0.0)->Label:
	var label:=Label.new()
	label.text=text
	return style_label(label,size,color,spacing_em)

static func readable_report(bbcode:String)->String:
	if not is_light():return bbcode
	var pattern:=RegEx.new();pattern.compile("\\[color=(#[0-9a-fA-F]{6})\\]")
	var result:=bbcode
	for match_result:RegExMatch in pattern.search_all(bbcode):
		var ink:=Color(match_result.get_string(1))
		var background:=DOCK_BG.srgb_to_linear().get_luminance()
		for step in 20:
			var foreground:=ink.srgb_to_linear().get_luminance()
			if (background+.05)/(foreground+.05)>=4.5:break
			ink=ink.darkened(.10)
		result=result.replace(match_result.get_string(),"[color=#"+ink.to_html(false)+"]")
	return result
