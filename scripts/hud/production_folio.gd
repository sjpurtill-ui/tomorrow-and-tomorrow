extends RefCounted
## Presentation vocabulary local to the workshops: open paper, quiet rules,
## named quantities and the existing product illustrations.
const T=preload("res://scripts/hud/hud_tokens.gd")
const Art=preload("res://scripts/hud/production_art.gd")
const Icons=preload("res://scripts/resource_icons.gd")

static func product_texture(item:String,size:int=96)->Texture2D:
	# Only the four exact subjects in the atlas use paintings. Other products
	# retain their own equipment mark; a generic bench must not impersonate them.
	if T.color_mode!="dark" and item in ["spear","woven_cloth","bow","transport_cart"]:
		return Art.texture(Art.product(item))
	return Icons.equipment_texture(item,T.INK,T.GOLD,size)

static func label(text:String,role:String="small",tone:Color=T.INK)->Label:
	var result:=Label.new();result.text=text;T.text(result,role,tone)
	# Short readings carry their natural width. Narrative callers opt in to
	# wrapping only after assigning an expanding column.
	result.autowrap_mode=TextServer.AUTOWRAP_OFF
	result.mouse_filter=Control.MOUSE_FILTER_PASS
	return result

static func heading(parent:Node,text:String,note:String="")->Label:
	var title:=label(text,"voice",T.INK);title.add_theme_font_override("font",T.font("voice_bold"));parent.add_child(title)
	if not note.is_empty():parent.add_child(label(note,"small",T.INK_MUTED))
	return title

static func rule_style(padding:int=12)->StyleBoxFlat:
	var style:=T.flat(Color.TRANSPARENT,T.RULE,0,0)
	style.border_color=T.RULE
	style.border_width_bottom=1
	style.content_margin_top=padding;style.content_margin_bottom=padding
	return style

static func group(parent:Node,caption:String)->VBoxContainer:
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",5);parent.add_child(column)
	column.add_child(label(caption,"small",T.INK_MUTED))
	return column

static func focus_style()->StyleBoxFlat:
	return T.flat(Color.TRANSPARENT,T.GOLD_TEXT,2,T.RADIUS_CONTROL)
