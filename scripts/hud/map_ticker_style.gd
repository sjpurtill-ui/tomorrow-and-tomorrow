extends RefCounted
## THE MAP TICKER ON PAPER (codex/beauty-3): the one-line status strip over
## the map (the Chronicle's latest tale, travel and founding notices) was 10 px
## gold type straight on the land, unreadable over bright grass. It now sits
## on a small paper slip hanging under the top bar, in the UI face at a
## readable size, in ink, and fits its text: an empty ticker shows no slip.

const HudT:=preload("res://scripts/hud/hud_tokens.gd")
const TOP:=74.0
const PAD:=Vector2(16.0,5.0)

static func style(label:Label)->void:
	var slip:=StyleBoxFlat.new()
	slip.bg_color=Color(HudT.PANEL_BG_SOLID,0.95)
	slip.border_color=Color(HudT.BORDER_SOFT,0.9)
	slip.set_border_width_all(1)
	slip.set_corner_radius_all(2)
	slip.content_margin_left=PAD.x;slip.content_margin_right=PAD.x
	slip.content_margin_top=PAD.y;slip.content_margin_bottom=PAD.y
	slip.shadow_color=Color(0.12,0.09,0.05,0.16)
	slip.shadow_size=6;slip.shadow_offset=Vector2(0,2)
	label.add_theme_stylebox_override("normal",slip)
	label.add_theme_font_override("font",HudT.FONT_UI)
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",HudT.INK)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.clip_text=true
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.set_meta("ticker_fitted","")

## Sizes the slip to its text, centred over the map. Cheap when the text and
## width are unchanged; hides the slip when there is nothing to say.
static func fit(label:Label,viewport_width:float)->void:
	# Older systems still hand the ticker shouted text; it reads as a sentence.
	var calm:=preload("res://scripts/hud/paper_kit.gd").calm_line(label.text)
	if calm!=label.text.strip_edges() and calm!="":label.text=calm
	var key:="%s|%d" % [label.text,roundi(viewport_width)]
	if String(label.get_meta("ticker_fitted",""))==key:return
	label.set_meta("ticker_fitted",key)
	if label.text.strip_edges()=="":
		label.self_modulate.a=0.0
		return
	label.self_modulate.a=1.0
	var font:Font=label.get_theme_font("font")
	var width:=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x
	var usable:=maxf(240.0,viewport_width-HudT.RAIL_WIDTH-48.0)
	var box:=Vector2(minf(width+PAD.x*2.0+4.0,usable),28.0)
	label.size=box
	label.position=Vector2(HudT.RAIL_WIDTH+(viewport_width-HudT.RAIL_WIDTH-box.x)*0.5,TOP)
