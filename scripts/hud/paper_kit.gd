extends RefCounted
## PAPER KIT: one small set of builders for the map's own cards (the ground
## survey, the founding site review, map help, road notices, alerts, the
## rename card, the settler card and the game menu). Every card is opaque
## paper with a 1 px rule, ink text at 12 px or more, sentence case and
## plain buttons. Accent colours used as text pass 4.5:1 on the card.

const T:=preload("res://scripts/hud/hud_tokens.gd")

## The raised paper card, with padding.
static func card_style(pad:float=16.0,accent:Color=Color(0,0,0,0))->StyleBoxFlat:
	var style:=T.paper_panel_style(true,T.RADIUS_CARD,pad)
	if accent.a>0.0:
		# A coloured top rule, never a coloured fill.
		style.border_color=T.RULE
		style.border_width_top=3
		style.border_color=accent
		style.border_width_left=1;style.border_width_right=1;style.border_width_bottom=1
	style.shadow_color=Color(0.12,0.09,0.05,0.18 if T.is_light() else 0.45)
	style.shadow_size=12;style.shadow_offset=Vector2(0,4)
	return style

## A sunk section inside a card (rows, grouped facts).
static func section_style(pad:float=10.0)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=T.PAPER_SUNK
	style.border_color=T.RULE
	style.set_border_width_all(1)
	style.set_corner_radius_all(T.RADIUS_CONTROL)
	style.set_content_margin_all(pad)
	return style

static func panel(accent:Color=Color(0,0,0,0),pad:float=16.0)->PanelContainer:
	var node:=PanelContainer.new()
	node.theme=T.control_theme()
	node.add_theme_stylebox_override("panel",card_style(pad,accent))
	node.mouse_filter=Control.MOUSE_FILTER_STOP
	return node

static func section(parent:Node,pad:float=10.0)->VBoxContainer:
	var box:=PanelContainer.new()
	box.add_theme_stylebox_override("panel",section_style(pad))
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	box.add_child(column)
	return column

## Text roles: "kicker" (12 px caps, muted), "title" (20 px ink),
## "heading" (16 px ink), "body" (14 px), "note" (13 px muted), "value" (16 px).
static func label(parent:Node,text:String,role:String="body",color:Color=Color(0,0,0,0),wrap:bool=true)->Label:
	var node:=Label.new()
	var size:=14
	var ink:=T.BODY
	match role:
		"kicker":size=12;ink=T.INK_MUTED;text=text.to_upper()
		"title":size=20;ink=T.INK
		"heading":size=16;ink=T.INK
		"value":size=16;ink=T.INK
		"note":size=13;ink=T.INK_MUTED
		_:size=14;ink=T.BODY
	node.text=text
	node.add_theme_font_override("font",T.font("ui_strong") if role in ["kicker","title","heading","value"] else T.FONT_UI)
	node.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size))
	node.add_theme_color_override("font_color",text_color(color) if color.a>0.0 else ink)
	if wrap:
		node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if parent!=null:parent.add_child(node)
	return node

## A plain text button. Primary buttons carry the gold rule.
static func button(parent:Node,text:String,primary:bool=false,on_press:Callable=Callable(),tip:String="")->Button:
	var node:=Button.new()
	node.text=text
	node.tooltip_text=tip
	node.custom_minimum_size=Vector2(0,36)
	node.add_theme_font_override("font",T.font("ui_strong") if primary else T.FONT_UI)
	node.add_theme_font_size_override("font_size",15)
	node.add_theme_color_override("font_color",T.INK)
	node.add_theme_color_override("font_hover_color",T.INK)
	node.add_theme_color_override("font_disabled_color",T.DISABLED)
	node.add_theme_stylebox_override("normal",T.action_button_style(primary))
	node.add_theme_stylebox_override("hover",T.action_button_style(primary,true))
	node.add_theme_stylebox_override("pressed",T.button_pressed_style())
	node.add_theme_stylebox_override("disabled",T.button_disabled_style())
	node.add_theme_stylebox_override("focus",T.gold_outline_style())
	if on_press.is_valid():node.pressed.connect(on_press)
	if parent!=null:parent.add_child(node)
	return node

## A quiet button with no frame (Close, Later).
static func quiet_button(parent:Node,text:String,on_press:Callable=Callable(),tip:String="")->Button:
	var node:=button(parent,text,false,on_press,tip)
	node.flat=true
	node.add_theme_color_override("font_color",T.INK_MUTED)
	node.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	return node

## Accent colours are drawn for bars and rules at their true value; as text
## they use the shared text twins (HudTokens.text_for), and any other colour
## is made legible on the raised card.
static func text_color(accent:Color)->Color:
	var twin:=T.text_for(accent)
	if twin!=accent:return twin
	return T.legible(Color(accent,1.0),T.PAPER_RAISED)

static func contrast(a:Color,b:Color)->float:
	return T.contrast(a,b)

## Sentence case for text that arrives in capitals from older systems. Mixed
## case is left alone, so names inside sentences survive.
static func sentence(text:String)->String:
	var clean:=text.strip_edges()
	if clean=="":return clean
	var letters:=0
	var upper:=0
	for character in clean:
		if character.to_lower()!=character.to_upper():
			letters+=1
			if character==character.to_upper():upper+=1
	if letters<4 or float(upper)/float(letters)<0.8:return clean
	return T.sentence_case(clean)

## Every date on these cards: season and year, never a raw day count.
static func when(day:int)->String:
	return preload("res://scripts/hud/era_words.gd").when(day)

## A paper card centred over a dimmed map, for decisions that pause play.
## Returns [overlay, card_column].
static func modal(host:Node,width:float,accent:Color=Color(0,0,0,0),node_name:String="PaperModal")->Array:
	var overlay:=Control.new()
	overlay.name=node_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.theme=T.control_theme()
	overlay.set_meta("responsive_scroll_layout",true)
	host.add_child(overlay)
	var scrim:=ColorRect.new()
	scrim.name="Scrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color=T.SCRIM
	overlay.add_child(scrim)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var card:=panel(accent,24.0)
	card.name="Card"
	var view:=host.get_viewport().get_visible_rect().size if host.get_viewport() else Vector2(1600,900)
	card.custom_minimum_size.x=minf(width,view.x-32.0)
	center.add_child(card)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	card.add_child(column)
	return [overlay,column]
