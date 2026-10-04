class_name HudTokens
## Design tokens for the Command Rail HUD (design resolution 1920x1080).
## Source: design_handoff_command_rail_hud/README.md — values are final.

# Runtime palette. DisplayPreferences sets it before the HUD is constructed.
static var color_mode:="light"
static var PANEL_BG:=Color("e9dfcf")
static var PANEL_BG_SOLID:=Color("eee5d6")
static var DOCK_BG:=Color("f2eadc")
static var TILE_BG:=Color("dfd2be")
static var ROW_BG:=Color("e8dece")
static var ACTIVE_BG:=Color("d3c1a5")
static var HOVER_BG:=Color("ddd0bd")
static var CLOSE_HOVER_BG:=Color("dfc8bd")
static var BUTTON_BG:=Color("e0d4c2")
static var FIELD_BG:=Color("f7f1e7")
static var SPEED_IDLE_BG:=Color("ded2c0")
static var TRACK:=Color("c9baa4")
static var TOOLBAR_BG:=Color("ebe1d2f2")
static var MAP_LABEL_BG:=Color("eee5d7e8")
static var BORDER:=Color("9b896e")
static var BORDER_2:=Color("87745b")
static var BORDER_SOFT:=Color("b9a991")
static var LAYER_ON_BORDER:=Color("537d76")
static var INK:=Color("20231f")
static var BODY:=Color("30352f")
static var BODY_2:=Color("3e443d")
static var TEXT_SOFT:=Color("49524b")
static var TEXT_DIM:=Color("49524b")
static var MUTED:=Color("49524b")
static var DISABLED:=Color("6b6e68")
static var LAYER_ON_FG:=Color("343b37")
static var GOLD:=Color("8a6118")
static var GOLD_BRIGHT:=Color("6c480c")
static var GOLD_WASH:=Color(141.0/255.0,108.0/255.0,32.0/255.0,0.12)
static var GREEN:=Color("536d32")
static var RED:=Color("a34435")
static var AMBER:=Color("805d1d")
static var TEAL:=Color("356f66")
static var BLUE:=Color("4d6389")
static var VIOLET:=Color("695587")
## Text-safe accents. The plain accents above are for bars, rules, stripes and
## icons; they fall near 3.3:1 on paper. Any accent that colours TEXT uses its
## *_TEXT twin, which reads at 4.5:1 or better on every paper ground (PANEL_BG,
## DOCK_BG, TILE_BG, ROW_BG, PAPER, PAPER_RAISED, PAPER_SUNK, ACTIVE_BG) in
## light mode and on every night ground in dark mode. tests/test_button_contrast.gd
## checks each pair. text_for(accent) maps an accent to its twin.
static var GREEN_TEXT:=Color("425627")
static var RED_TEXT:=Color("84372b")
static var AMBER_TEXT:=Color("664a17")
static var TEAL_TEXT:=Color("295750")
static var BLUE_TEXT:=Color("3e506f")
static var VIOLET_TEXT:=Color("584771")
static var GOLD_TEXT:=Color("694a12")
static var DARK_INK:=Color("111111")
static var GLYPH_DARK:=Color("f4efe5")
static var WARN_BG:=Color(141.0/255.0,108.0/255.0,32.0/255.0,0.10)
static var WARN_BORDER:=Color("8d6c20")
static var DANGER_BG:=Color(166.0/255.0,79.0/255.0,64.0/255.0,0.10)
static var DANGER_BORDER:=Color("a64f40")
static var INFO_BG:=Color(66.0/255.0,124.0/255.0,115.0/255.0,0.10)
static var INFO_BORDER:=Color("427c73")
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
const RADIUS_CONTROL:=2
const RADIUS_CARD:=4
const MOTION:={"fast":0.12,"base":0.20,"slow":0.36,"scene":0.90}
## Role -> [face, size]. Faces: "display", "voice", "voice_italic", "ui", "ui_strong".
const TYPE:={"display":["display",40],"title":["display",28],"voice":["voice",22],
	"voice_small":["voice",18],"value":["ui_strong",20],"body":["ui",16],"small":["ui",14],"kicker":["ui_strong",12]}
## Chrome palette: one paper language for the rail, panels and scene headers.
static var PAPER:=Color("efe6d4")
static var PAPER_RAISED:=Color("f6efe1")
static var PAPER_SUNK:=Color("e3d7c0")
static var RULE:=Color("b7a383")
static var RULE_STRONG:=Color("8c7757")
static var INK_MUTED:=Color("594e41")
static var SCRIM:=Color(31.0/255.0,26.0/255.0,20.0/255.0,0.55)
static var _fonts:Dictionary={}

static func _set_chrome_palette()->void:
	if color_mode=="dark":
		PAPER=Color("0c1518");PAPER_RAISED=Color("111c1f");PAPER_SUNK=Color("0a1214");RULE=Color("2a3538");RULE_STRONG=Color("3e5256");INK_MUTED=Color("a0937e");SCRIM=Color(0,0,0,0.65)
	else:
		PAPER=Color("efe6d4");PAPER_RAISED=Color("f6efe1");PAPER_SUNK=Color("e3d7c0");RULE=Color("b7a383");RULE_STRONG=Color("8c7757");INK_MUTED=Color("594e41");SCRIM=Color(31.0/255.0,26.0/255.0,20.0/255.0,0.55)

static func font(face:String)->Font:
	## Shared font resources, one per face; never a SystemFont.
	if _fonts.has(face):return _fonts[face]
	var result:Font
	match face:
		"display":result=FONT_DISPLAY
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
	color_mode="dark" if mode=="dark" else "light"
	_control_theme=null
	_set_chrome_palette()
	if color_mode=="dark":
		PANEL_BG=Color(8.0/255.0,13.0/255.0,15.0/255.0);PANEL_BG_SOLID=Color(8.0/255.0,13.0/255.0,15.0/255.0);DOCK_BG=Color(9.0/255.0,15.0/255.0,17.0/255.0)
		TILE_BG=Color("0e181b");ROW_BG=Color("0c1518");ACTIVE_BG=Color("16222a");HOVER_BG=Color("111c1f");CLOSE_HOVER_BG=Color("1a2427");BUTTON_BG=Color("131d20");FIELD_BG=Color("0a1214");SPEED_IDLE_BG=Color("0d1719");TRACK=Color("1b2528");TOOLBAR_BG=Color("080d0feb");MAP_LABEL_BG=Color("060a0bbf")
		BORDER=Color("2a3538");BORDER_2=Color("2f3b3e");BORDER_SOFT=Color("223034");LAYER_ON_BORDER=Color("7ca39d")
		INK=Color("f0e6d1");BODY=Color("e4dfd2");BODY_2=Color("d8d3c6");TEXT_SOFT=Color("b6bdb7");TEXT_DIM=Color("a9b0ab");MUTED=Color("8a948f");DISABLED=Color("6f7a77");LAYER_ON_FG=Color("d7d0bf")
		GOLD=Color("c9a95a");GOLD_BRIGHT=Color("ead078");GOLD_WASH=Color(201.0/255.0,169.0/255.0,90.0/255.0,0.12);GREEN=Color("8fa26a");RED=Color("c67462");AMBER=Color("d0b46f");TEAL=Color("79a8a0");BLUE=Color("8798b5");VIOLET=Color("a897c9");GLYPH_DARK=Color("0d1416")
		GREEN_TEXT=Color("9bae76");RED_TEXT=Color("d58672");AMBER_TEXT=Color("d0b46f");TEAL_TEXT=Color("86b4ac");BLUE_TEXT=Color("97a7c2");VIOLET_TEXT=Color("b4a5d3");GOLD_TEXT=Color("d4b466")
		WARN_BG=Color(201.0/255.0,169.0/255.0,90.0/255.0,0.08);WARN_BORDER=Color("7d6a3a");DANGER_BG=Color(198.0/255.0,116.0/255.0,98.0/255.0,0.12);DANGER_BORDER=Color("8a4f44");INFO_BG=Color(121.0/255.0,168.0/255.0,160.0/255.0,0.10);INFO_BORDER=Color("3e5f5a")
	else:
		PANEL_BG=Color("e9dfcf");PANEL_BG_SOLID=Color("eee5d6");DOCK_BG=Color("f2eadc");TILE_BG=Color("dfd2be");ROW_BG=Color("e8dece");ACTIVE_BG=Color("d3c1a5");HOVER_BG=Color("ddd0bd");CLOSE_HOVER_BG=Color("dfc8bd");BUTTON_BG=Color("e0d4c2");FIELD_BG=Color("f7f1e7");SPEED_IDLE_BG=Color("ded2c0");TRACK=Color("c9baa4");TOOLBAR_BG=Color("ebe1d2f2");MAP_LABEL_BG=Color("eee5d7e8")
		BORDER=Color("9b896e");BORDER_2=Color("87745b");BORDER_SOFT=Color("b9a991");LAYER_ON_BORDER=Color("4b746c");INK=Color("20231f");BODY=Color("30352f");BODY_2=Color("3e443d");TEXT_SOFT=Color("49524b");TEXT_DIM=Color("49524b");MUTED=Color("49524b");DISABLED=Color("6b6e68");LAYER_ON_FG=Color("30362f")
		GOLD=Color("8a6118");GOLD_BRIGHT=Color("6c480c");GOLD_WASH=Color(138.0/255.0,97.0/255.0,24.0/255.0,0.13);GREEN=Color("536d32");RED=Color("a34435");AMBER=Color("805d1d");TEAL=Color("356f66");BLUE=Color("4d6389");VIOLET=Color("695587");GLYPH_DARK=Color("f4efe5")
		GREEN_TEXT=Color("425627");RED_TEXT=Color("84372b");AMBER_TEXT=Color("664a17");TEAL_TEXT=Color("295750");BLUE_TEXT=Color("3e506f");VIOLET_TEXT=Color("584771");GOLD_TEXT=Color("694a12")
		WARN_BG=Color(141.0/255.0,108.0/255.0,32.0/255.0,0.10);WARN_BORDER=Color("8d6c20");DANGER_BG=Color(166.0/255.0,79.0/255.0,64.0/255.0,0.10);DANGER_BORDER=Color("a64f40");INFO_BG=Color(66.0/255.0,124.0/255.0,115.0/255.0,0.10);INFO_BORDER=Color("427c73")

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
	style.bg_color=Color("f8f3ea") if is_light() else Color(12.0/255.0,20.0/255.0,22.0/255.0,0.98)
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
const QUEUE_WIDTH:=400.0

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
	var border:=GOLD if (primary or hover) else BORDER_2
	var style:=flat(BUTTON_BG,border,1,3)
	style.content_margin_left=12.0
	style.content_margin_right=12.0
	return style

static func button_pressed_style()->StyleBoxFlat:
	## Held down or toggled on: the darker active ground under a gold rule.
	var style:=flat(ACTIVE_BG,GOLD,1,3)
	style.content_margin_left=12.0
	style.content_margin_right=12.0
	return style

static func button_disabled_style()->StyleBoxFlat:
	## A resting control: flatter ground and a soft rule, never Godot's grey
	## wash. Its DISABLED label still reads at 3:1 or better.
	var style:=flat(PANEL_BG,BORDER_SOFT,1,3)
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
