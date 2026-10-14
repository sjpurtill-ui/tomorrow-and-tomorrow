extends Button
## Purpose, gains and costs are visible before selection.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Brief:=preload("res://scripts/hud/course_choice_brief.gd")
var art_index:=0
var caption:=""
var subtitle:=""
var course_id:=""
var accent:=Color("c5a55d")
var chosen:=false
var artwork:TextureRect
var title_label:Label
var outline:Panel
var content:VBoxContainer

func _ready()->void:
	text=caption
	clip_text=true
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:
		var style:=StyleBoxFlat.new();style.bg_color=T.PAPER_RAISED
		style.border_color=T.ACTION if state in ["hover","focus","pressed"] else T.RULE
		style.set_border_width_all(1);style.set_corner_radius_all(T.RADIUS_CARD)
		add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_hover_pressed_color"]:add_theme_color_override(state,Color.TRANSPARENT)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,12)
	add_child(margin)
	content=VBoxContainer.new();content.add_theme_constant_override("separation",5);content.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(content)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(top)
	var words:=VBoxContainer.new();words.size_flags_horizontal=SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);words.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(words)
	title_label=_line(words,caption,T.INK,19);title_label.name="CourseTitle"
	var reading:=Brief.brief(course_id)
	_line(words,String(reading.why),T.INK,14).name="CoursePurpose"
	artwork=TextureRect.new();artwork.name="CourseIcon";artwork.custom_minimum_size=Vector2(54,52);artwork.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;artwork.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(artwork)
	artwork.texture=preload("res://scripts/hud/ambition_art.gd").texture(art_index)
	artwork.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_line(content,String(reading.gains),T.GREEN_TEXT,14).name="CourseGains"
	_line(content,"Trade-off: "+String(reading.costs),T.AMBER_TEXT,14).name="CourseCosts"
	_line(content,String(reading.research),T.INK_MUTED,14).name="CourseResearch"
	outline=Panel.new();outline.mouse_filter=Control.MOUSE_FILTER_IGNORE;outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border:=StyleBoxFlat.new();border.bg_color=Color.TRANSPARENT;border.border_color=T.ACTION;border.set_border_width_all(1);border.border_width_left=4;border.set_corner_radius_all(T.RADIUS_CARD);outline.add_theme_stylebox_override("panel",border);add_child(outline);outline.visible=chosen
	content.minimum_size_changed.connect(_fit)
	resized.connect(_fit);_fit.call_deferred()

func _line(parent:Node,value:String,color:Color,font_size:int)->Label:
	var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=SIZE_EXPAND_FILL;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color",color);label.add_theme_font_size_override("font_size",font_size);parent.add_child(label);return label

func _fit()->void:
	if is_instance_valid(content):custom_minimum_size.y=maxf(156,content.get_combined_minimum_size().y+24)

func select(value:bool)->void:
	chosen=value
	if is_instance_valid(outline):outline.visible=value
	if is_instance_valid(title_label):title_label.add_theme_color_override("font_color",T.GOLD_TEXT if value else T.INK)
