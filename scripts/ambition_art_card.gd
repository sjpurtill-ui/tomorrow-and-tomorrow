extends Button
var art_index:=0
var caption:=""
var subtitle:=""
var accent:=Color("c5a55d")
var chosen:=false
var artwork:TextureRect
var footer:ColorRect
var title_label:Label
var sub_label:Label
var outline:Panel

func _ready()->void:
	clip_contents=true
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("112126")
		style.border_color=accent if state in ["hover","focus","pressed"] else Color("385052")
		style.set_border_width_all(2 if state in ["hover","focus","pressed"] else 1)
		add_theme_stylebox_override(state,style)
	artwork=TextureRect.new();artwork.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;artwork.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE;artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(artwork)
	var path:="res://assets/ui/ambition_atlas_v1.png"
	if ResourceLoader.exists(path):
		var source:Texture2D=load(path);var atlas:=AtlasTexture.new();atlas.atlas=source;atlas.region=Rect2(Vector2(art_index%4,art_index/4)*source.get_size()/Vector2(4,2),source.get_size()/Vector2(4,2));artwork.texture=atlas
	footer=ColorRect.new();footer.color=Color(.025,.055,.064,.9);footer.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(footer)
	title_label=Label.new();title_label.text=caption;title_label.add_theme_color_override("font_color",Color("fff3d6"));title_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(title_label)
	sub_label=Label.new();sub_label.text=subtitle;sub_label.add_theme_color_override("font_color",Color("c8d4cf"));sub_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(sub_label)
	outline=Panel.new();outline.mouse_filter=Control.MOUSE_FILTER_IGNORE;outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border:=StyleBoxFlat.new();border.bg_color=Color.TRANSPARENT;border.border_color=accent;border.set_border_width_all(3);outline.add_theme_stylebox_override("panel",border);add_child(outline);outline.visible=chosen
	resized.connect(_fit);mouse_entered.connect(func():artwork.modulate=Color(1.12,1.12,1.12));mouse_exited.connect(func():artwork.modulate=Color.WHITE);_fit()

func _fit()->void:
	if not is_instance_valid(footer):return
	var compact:=size.y<180
	footer.position=Vector2(0,size.y-(57 if compact else 70));footer.size=Vector2(size.x,70)
	title_label.position=footer.position+Vector2(12,5);title_label.size=Vector2(size.x-24,27);title_label.add_theme_font_size_override("font_size",16 if size.x<210 else 21)
	sub_label.position=footer.position+Vector2(12,32);sub_label.size=Vector2(size.x-24,21);sub_label.add_theme_font_size_override("font_size",11 if size.x<210 else 13)
	queue_redraw()

func _draw()->void:
	if chosen:draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),accent,false,3)

func select(value:bool)->void:
	chosen=value
	if is_instance_valid(outline):outline.visible=value
	if is_instance_valid(title_label):title_label.text=("✓ " if value else "")+caption
	queue_redraw()
