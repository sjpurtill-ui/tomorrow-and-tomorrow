extends PanelContainer
## One production line, HOI4-style: its place in the list (priority), the
## product, who it is for, the output bar, hands −/+ (quick ×5), the store
## target −/+ (or build 1 / ∞ for boats), skill, and pause / close. Numbers
## and marks on the row; the sentences live in the tooltips.
##
## Built once per screen shape, then apply(view) refreshes it in place, so a
## daily refresh never closes the tooltip the player is reading. Every press
## goes through screen.act(id, action, value).
const T:=preload("res://scripts/hud/hud_tokens.gd")
const W:=preload("res://scripts/hud/production_widgets.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
## Column widths, shared with the column heads above the list.
const ART_WIDTH:=44.0
const BAR_MIN_WIDTH:=140.0
const HANDS_WIDTH:=124.0
const TARGET_WIDTH:=100.0
const SKILL_WIDTH:=72.0
const COLUMN_GAP:=10
const PAD_LEFT:=12
const PAD_RIGHT:=8

var screen:Node
var view:Dictionary={}
var rank:Label
var rank_box:PanelContainer
var title:Button
var badge:W.Chip
var auto:Button
var up:W.IconButton
var down:W.IconButton
var pause:W.IconButton
var close:W.IconButton
var picture:TextureRect
var stock:Label
var bar:W.OutputBar
var hands_down:W.IconButton
var hands_value:Label
var hands_up:W.IconButton
var hands_five:Button
var keep_down:W.IconButton
var keep_value:Label
var keep_up:W.IconButton
var repeat_one:Button
var repeat_always:Button
var skill:W.SkillGraph
var _arm_close:=false

func build(owner_screen:Node,first:Dictionary)->void:
	screen=owner_screen;view=first
	name="Line%d" % int(first.id)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",8);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(top)
	rank_box=PanelContainer.new();rank_box.name="Rank";rank_box.custom_minimum_size=Vector2(24,24);rank_box.mouse_filter=Control.MOUSE_FILTER_PASS
	rank_box.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CONTROL));top.add_child(rank_box)
	rank=Label.new();T.text(rank,"small",T.INK);rank.add_theme_font_override("font",T.font("ui_strong"));rank.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rank.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;rank_box.add_child(rank)
	title=Button.new();title.name="Name";title.flat=true;title.focus_mode=Control.FOCUS_NONE;title.alignment=HORIZONTAL_ALIGNMENT_LEFT
	T.text(title,"body",T.INK);title.add_theme_font_override("font",T.font("ui_strong"));title.add_theme_color_override("font_hover_color",T.GOLD_TEXT)
	title.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	title.pressed.connect(func():screen.act(int(view.id),"detail",0.0));top.add_child(title)
	badge=W.Chip.new();badge.name="Badge";top.add_child(badge)
	auto=W.text_button("Auto","");auto.name="Auto";auto.toggle_mode=false;top.add_child(auto)
	auto.pressed.connect(func():screen.act(int(view.id),"auto",0.0 if bool(view.managed) else 1.0))
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(spacer)
	up=W.IconButton.new("up","",24,true);up.name="Up";top.add_child(up)
	up.pressed.connect(func():screen.act(int(view.id),"move",-1.0))
	down=W.IconButton.new("down","",24,true);down.name="Down";top.add_child(down)
	down.pressed.connect(func():screen.act(int(view.id),"move",1.0))
	pause=W.IconButton.new("pause","",24,true);pause.name="Pause";top.add_child(pause)
	pause.pressed.connect(func():screen.act(int(view.id),"pause",0.0))
	close=W.IconButton.new("close","",24,true);close.name="Close";close.danger=true;top.add_child(close)
	close.pressed.connect(_on_close)
	var body:=HBoxContainer.new();body.name="Body";body.add_theme_constant_override("separation",COLUMN_GAP);body.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(body)
	var art:=Control.new();art.name="Picture";art.custom_minimum_size=Vector2(ART_WIDTH,40);art.mouse_filter=Control.MOUSE_FILTER_PASS;body.add_child(art)
	picture=TextureRect.new();picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);picture.offset_right=-8;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;art.add_child(picture)
	stock=Label.new();stock.name="Stock";T.text(stock,"kicker",T.INK);stock.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	stock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);stock.grow_horizontal=Control.GROW_DIRECTION_BEGIN;stock.grow_vertical=Control.GROW_DIRECTION_BEGIN
	stock.add_theme_color_override("font_outline_color",T.PAPER_RAISED);stock.add_theme_constant_override("outline_size",4);stock.mouse_filter=Control.MOUSE_FILTER_IGNORE;art.add_child(stock)
	bar=W.OutputBar.new(BAR_MIN_WIDTH);bar.name="Output";bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(bar)
	var hands:=HBoxContainer.new();hands.name="Hands";hands.custom_minimum_size.x=HANDS_WIDTH;hands.alignment=BoxContainer.ALIGNMENT_CENTER
	hands.add_theme_constant_override("separation",3);hands.size_flags_vertical=Control.SIZE_SHRINK_CENTER;body.add_child(hands)
	hands_down=W.IconButton.new("minus","",24);hands_down.name="HandsDown";hands.add_child(hands_down)
	hands_down.pressed.connect(func():screen.act(int(view.id),"hands",-float(view.hands_step)))
	hands_value=Label.new();hands_value.name="HandsValue";T.text(hands_value,"body",T.INK);hands_value.add_theme_font_override("font",T.font("ui_strong"))
	hands_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hands_value.custom_minimum_size.x=34;hands_value.mouse_filter=Control.MOUSE_FILTER_PASS;hands.add_child(hands_value)
	hands_up=W.IconButton.new("plus","",24);hands_up.name="HandsUp";hands.add_child(hands_up)
	hands_up.pressed.connect(func():screen.act(int(view.id),"hands",float(view.hands_step)))
	hands_five=W.text_button("×5","",false,30);hands_five.name="HandsFive";hands.add_child(hands_five)
	hands_five.pressed.connect(func():screen.act(int(view.id),"hands",5.0*float(view.hands_step)))
	var keep:=HBoxContainer.new();keep.name="Keep";keep.custom_minimum_size.x=TARGET_WIDTH;keep.alignment=BoxContainer.ALIGNMENT_CENTER
	keep.add_theme_constant_override("separation",3);keep.size_flags_vertical=Control.SIZE_SHRINK_CENTER;body.add_child(keep)
	if bool(first.get("ship",false)):
		repeat_one=W.text_button("1","",false,34);repeat_one.name="RepeatOne";keep.add_child(repeat_one)
		repeat_one.pressed.connect(func():screen.act(int(view.id),"target",float(int(view.stock)+1)))
		repeat_always=W.text_button("∞","",false,34);repeat_always.name="RepeatAlways";keep.add_child(repeat_always)
		repeat_always.pressed.connect(func():screen.act(int(view.id),"target",0.0))
	else:
		keep_down=W.IconButton.new("minus","",24);keep_down.name="KeepDown";keep.add_child(keep_down)
		keep_down.pressed.connect(func():screen.act(int(view.id),"target",float(Plain.step_target(int(view.target),-1))))
		keep_value=Label.new();keep_value.name="KeepValue";T.text(keep_value,"body",T.INK);keep_value.add_theme_font_override("font",T.font("ui_strong"))
		keep_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;keep_value.custom_minimum_size.x=40;keep_value.mouse_filter=Control.MOUSE_FILTER_PASS;keep.add_child(keep_value)
		keep_up=W.IconButton.new("plus","",24);keep_up.name="KeepUp";keep.add_child(keep_up)
		keep_up.pressed.connect(func():screen.act(int(view.id),"target",float(Plain.step_target(int(view.target),1))))
	skill=W.SkillGraph.new();skill.name="Skill";skill.custom_minimum_size.x=SKILL_WIDTH;body.add_child(skill)
	apply(first)

func apply(next:Dictionary)->void:
	view=next
	var id:=int(view.id)
	var persistent:=bool(view.persistent)
	var paused:=bool(view.paused)
	var look:=String(view.look)
	var tone:={"good":T.GREEN,"warn":T.AMBER,"bad":T.RED}.get(look,T.RULE_STRONG) as Color
	var style:=T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD)
	style.border_color=T.RULE;style.border_width_left=4
	style.content_margin_left=PAD_LEFT;style.content_margin_right=PAD_RIGHT;style.content_margin_top=6;style.content_margin_bottom=8
	add_theme_stylebox_override("panel",style)
	_left_rule=tone;queue_redraw()
	rank.text=str(int(view.rank))
	var count:=int(view.get("count",1))
	rank_box.tooltip_text="Line %d of %d. Scarce materials go to line 1 first, then down the list. Drag the row or use the arrows to reorder." % [int(view.rank),count]
	title.text=String(view.name)
	title.tooltip_text=String(view.get("description",""))+("\n" if not String(view.get("description","")).is_empty() else "")+"Details, change product or close."
	var mark:Dictionary=view.get("badge",{})
	badge.visible=not mark.is_empty()
	if not mark.is_empty():badge.set_reading(String(mark.text),T.TEAL,String(mark.get("tip","")))
	auto.visible=bool(view.get("auto",false))
	W.style_text_button(auto,bool(view.managed))
	auto.tooltip_text=String(view.get("auto_tip",""))
	auto.disabled=not bool(view.get("auto_ready",true))
	up.disabled=int(view.rank)<=1;up.tooltip_text="Move up: first call on scarce materials before the lines below."
	down.disabled=int(view.rank)>=count;down.tooltip_text="Move down: the lines above get scarce materials first."
	pause.visible=persistent
	pause.set_glyph("play" if paused else "pause","Resume this line." if paused else "Pause this line. Work in progress is kept.")
	close.tooltip_text="Close this line. Finished goods stay in store; work in progress is lost."
	if not _arm_close:close.set_glyph("close")
	picture.texture=Icons.equipment_texture(String(view.item),T.INK,T.GOLD,64)
	var deficit:=int(view.get("deficit",0))
	stock.text=str(int(view.stock))
	stock.add_theme_color_override("font_color",T.RED_TEXT if deficit>0 else T.INK)
	var need:=int(view.get("needed",0))
	(picture.get_parent() as Control).tooltip_text="%d in store" % int(view.stock)+(", %d needed by the bands: short %d." % [need,deficit] if deficit>0 else (", %d needed by the bands." % need if need>0 else "."))
	bar.set_reading(float(view.progress),look,String(view.bar_text),String(view.tip))
	var step:=float(view.hands_step)
	hands_value.text=Plain.hands_text(float(view.hands))
	var total:=float(view.get("hands_total",0.0))
	hands_value.tooltip_text="%s of your %s craftspeople work this line." % [Plain.hands_text(float(view.hands)),Plain.hands_text(total)]
	var step_words:=Plain.hands_text(step)+(" hand" if is_equal_approx(step,1.0) else " hands")
	hands_down.tooltip_text="Take %s off; they go back to household crafting." % step_words
	hands_up.tooltip_text="Add %s: from household crafting, or from the lowest line when every craftsperson is busy." % step_words
	hands_five.tooltip_text="Add %s hands at once." % Plain.hands_text(step*5.0)
	for button:Button in [hands_down,hands_up,hands_five]:button.disabled=paused or total<=0.0
	hands_down.disabled=hands_down.disabled or float(view.hands)<.05
	if paused:
		for button:Button in [hands_up,hands_five]:button.tooltip_text="Resume the line to put hands on it."
	if keep_value!=null:
		var target:=int(view.target)
		keep_value.text=Plain.target_text(target)
		keep_value.tooltip_text=("Keep %d in store: the line rests when %d are in store and starts again when some are issued." % [target,target]) if target>0 else "No limit: the line keeps making until you pause it."
		keep_down.disabled=not persistent or target<=0;keep_up.disabled=not persistent
		keep_down.tooltip_text="Keep fewer in store.";keep_up.tooltip_text="Keep more in store."
	if repeat_one!=null:
		var always:=int(view.target)<=0
		W.style_text_button(repeat_one,not always);W.style_text_button(repeat_always,always)
		repeat_one.tooltip_text="Build one more, then rest.";repeat_always.tooltip_text="Keep building until you pause it."
	skill.set_reading(float(view.efficiency),String(view.get("skill_tip","")))
	tooltip_text=""

var _left_rule:=Color(0,0,0,0)
func _draw()->void:
	# The line's condition, as a rule down its left edge.
	if _left_rule.a>0.0:draw_rect(Rect2(Vector2.ZERO,Vector2(4,size.y)),_left_rule)

func _on_close()->void:
	if not _arm_close:
		_arm_close=true;close.set_glyph("close","Click again to close this line.");close.danger=true
		close.add_theme_stylebox_override("normal",T.flat(T.DANGER_BG,T.DANGER_BORDER,1,T.RADIUS_CONTROL))
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(self):
				_arm_close=false;close.restyle();close.tooltip_text="Close this line. Finished goods stay in store; work in progress is lost.")
		return
	screen.act(int(view.id),"close",0.0)

# --- Drag to reorder --------------------------------------------------------------

func _get_drag_data(_at:Vector2)->Variant:
	var preview:=Label.new();preview.text="%d  %s" % [int(view.rank),String(view.name)]
	T.text(preview,"body",T.INK)
	var plate:=PanelContainer.new();plate.add_theme_stylebox_override("panel",T.paper_panel_style(true,T.RADIUS_CARD,8));plate.add_child(preview)
	set_drag_preview(plate)
	return {"production_line":int(view.id)}

func _can_drop_data(_at:Vector2,data:Variant)->bool:
	return data is Dictionary and (data as Dictionary).has("production_line") and int(data.production_line)!=int(view.id)

func _drop_data(_at:Vector2,data:Variant)->void:
	screen.act(int(data.production_line),"move_to",float(int(view.rank)-1))
