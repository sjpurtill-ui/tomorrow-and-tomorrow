extends Button
## One direction card: a painting above, a paper caption below (paper and ink).
const T:=preload("res://scripts/hud/hud_tokens.gd")
var art_index:=0
var caption:=""
var subtitle:=""
var accent:=Color("c5a55d")
var chosen:=false
var artwork:TextureRect
var footer:Panel
var title_label:Label
var sub_label:Label
var outline:Panel
var paper_art:=false

func _ready()->void:
	paper_art=preload("res://scripts/hud/early_civ_art.gd").active()
	clip_contents=true
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxFlat.new();style.bg_color=T.PAPER_RAISED
		style.border_color=T.GOLD if state in ["hover","focus","pressed"] else T.RULE
		style.set_border_width_all(1);style.set_corner_radius_all(T.RADIUS_CARD)
		if state in ["hover","focus","pressed"]:style.border_width_top=3
		add_theme_stylebox_override(state,style)
	artwork=TextureRect.new();artwork.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;artwork.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(artwork)
	artwork.texture=preload("res://scripts/hud/ambition_art.gd").texture(art_index)
	artwork.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if paper_art:artwork.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	footer=Panel.new();footer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var paper:=StyleBoxFlat.new();paper.bg_color=T.PAPER_RAISED;paper.border_color=T.RULE;paper.border_width_top=1;footer.add_theme_stylebox_override("panel",paper);add_child(footer)
	title_label=Label.new();title_label.text=caption;T.text(title_label,"value",T.INK);title_label.clip_text=true;title_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(title_label)
	sub_label=Label.new();sub_label.text=subtitle;T.text(sub_label,"small",T.INK_MUTED);sub_label.clip_text=true;sub_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(sub_label)
	outline=Panel.new();outline.mouse_filter=Control.MOUSE_FILTER_IGNORE;outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border:=StyleBoxFlat.new();border.bg_color=Color.TRANSPARENT;border.border_color=T.GOLD;border.set_border_width_all(1);border.border_width_top=4;border.set_corner_radius_all(T.RADIUS_CARD);outline.add_theme_stylebox_override("panel",border);add_child(outline);outline.visible=chosen
	resized.connect(_fit);mouse_entered.connect(func():artwork.modulate=Color(1.08,1.08,1.08));mouse_exited.connect(func():artwork.modulate=Color.WHITE);_fit()

func _fit()->void:
	if not is_instance_valid(footer):return
	var footer_height:=60.0 if size.y<180 else 70.0
	footer.position=Vector2(0,size.y-footer_height);footer.size=Vector2(size.x,footer_height)
	artwork.position=Vector2.ZERO;artwork.size=Vector2(size.x,maxf(0,footer.position.y))
	T.text(title_label,"body" if size.x<210 else "value",T.INK)
	title_label.position=footer.position+Vector2(12,6);title_label.size=Vector2(size.x-24,26)
	sub_label.position=footer.position+Vector2(12,34);sub_label.size=Vector2(size.x-24,20)
	queue_redraw()

func select(value:bool)->void:
	chosen=value
	if is_instance_valid(outline):outline.visible=value
	if is_instance_valid(title_label):title_label.text=caption
	if is_instance_valid(sub_label):
		sub_label.text=("Chosen · "+subtitle) if value else subtitle
		sub_label.add_theme_color_override("font_color",T.GOLD_TEXT if value else T.INK_MUTED)
	queue_redraw()
