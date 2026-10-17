extends PanelContainer
## One production line, HOI4-style: its place in the list (priority), the
## product, who it is for, the output bar, hands −/+ (quick ×5), the store
## target −/+ (or build 1 / ∞ for boats), skill, and pause / close. Numbers
## and marks on the row; the sentences live in the tooltips.
##
## Built once per screen shape, then apply(view) refreshes it in place, so a
## daily refresh never closes the tooltip the player is reading. Every press
## goes through screen.act(id, action, value).
const Industrial=preload("res://scripts/hud/production_skin.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const W:=preload("res://scripts/hud/production_widgets.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Folio:=preload("res://scripts/hud/production_folio.gd")
const Pictures:=preload("res://scripts/hud/production_pictures.gd")
## Column widths, shared with the column heads above the list.
const ART_WIDTH:=88.0
const BAR_MIN_WIDTH:=120.0
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
var target_row:Pictures.TargetRow
var _arm_close:=false
## The line's condition colour, drawn as a rule down its left edge.
var _left_rule:=Color(0,0,0,0)

var capacity_grid:GridContainer
var shortage:Label
var efficiency_bar:ProgressBar
const OLIVE:=Color("344033")
const STEEL:=Color("242925")
const LIGHT:=Color("dddcc8")

func build(owner_screen:Node,first:Dictionary)->void:
	screen=owner_screen;view=first
	name="Line%d" % int(first.id)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",3);add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",4);column.add_child(top)
	rank_box=PanelContainer.new();rank_box.name="Rank";rank_box.custom_minimum_size=Vector2(20,22);top.add_child(rank_box)
	rank=Folio.label("","small",LIGHT);rank.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rank_box.add_child(rank)
	title=W.text_button("", "Equipment details and change product");title.name="Name";title.alignment=HORIZONTAL_ALIGNMENT_LEFT;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.clip_text=true;top.add_child(title)
	title.pressed.connect(func():screen.act(int(view.id),"detail",0.0))
	for kind:String in ["up","down","pause","close"]:
		var button:=W.IconButton.new(kind,"",22,true);top.add_child(button)
		match kind:
			"up":up=button;up.name="Up";up.pressed.connect(func():screen.act(int(view.id),"move",-1.0))
			"down":down=button;down.name="Down";down.pressed.connect(func():screen.act(int(view.id),"move",1.0))
			"pause":pause=button;pause.name="Pause";pause.pressed.connect(func():screen.act(int(view.id),"pause",0.0))
			"close":close=button;close.name="Close";close.pressed.connect(_on_close)
	var body:=HBoxContainer.new();body.name="Body";body.add_theme_constant_override("separation",8);column.add_child(body)
	var art:=Control.new();art.name="Picture";art.custom_minimum_size=Vector2(66,40);body.add_child(art)
	picture=TextureRect.new();picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);art.add_child(picture)
	var reading:=VBoxContainer.new();reading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;reading.add_theme_constant_override("separation",2);body.add_child(reading)
	bar=W.OutputBar.new(110);bar.ink_override=LIGHT;bar.name="Output";bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.custom_minimum_size.y=20;reading.add_child(bar)
	efficiency_bar=ProgressBar.new();efficiency_bar.name="Efficiency";efficiency_bar.show_percentage=false;efficiency_bar.custom_minimum_size.y=7
	efficiency_bar.add_theme_stylebox_override("background",Industrial.flat(Color("191d19")));efficiency_bar.add_theme_stylebox_override("fill",Industrial.flat(Color("7f9b4c")));reading.add_child(efficiency_bar)
	var state:=Folio.label("","small",LIGHT);state.name="Condition";state.add_theme_font_size_override("font_size",12);reading.add_child(state)
	var allocation:=VBoxContainer.new();allocation.add_theme_constant_override("separation",2);body.add_child(allocation)
	capacity_grid=GridContainer.new();capacity_grid.name="CapacityGrid";capacity_grid.columns=5;capacity_grid.add_theme_constant_override("h_separation",2);capacity_grid.add_theme_constant_override("v_separation",2);allocation.add_child(capacity_grid)
	for index in 15:
		var slot:=CapacitySlot.new();slot.custom_minimum_size=Vector2(19,14);slot.focus_mode=Control.FOCUS_ALL;capacity_grid.add_child(slot)
		slot.pressed.connect(func():
			var scale:=maxi(1,ceili(float(view.get("hands_total",0))/15.0))
			var desired:=mini(int(view.get("hands_total",0)),(index+1)*scale)
			screen.act(int(view.id),"hands",float(desired-int(view.hands))))
	var controls:=HBoxContainer.new();controls.name="LineControls";controls.add_theme_constant_override("separation",4);column.add_child(controls)
	stock=Folio.label("","small",LIGHT);stock.name="Stock";controls.add_child(stock)
	controls.add_child(Folio.label(" stored   ","small",LIGHT))
	shortage=Folio.label("","small",LIGHT);shortage.name="ResourcePenalty";shortage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_child(shortage)
	controls.add_child(Folio.label("Makers", "small", LIGHT))
	hands_down=W.IconButton.new("minus","",22);hands_down.name="HandsDown";controls.add_child(hands_down);hands_down.pressed.connect(func():screen.act(int(view.id),"hands",-float(view.hands_step)))
	hands_value=Folio.label("","small",LIGHT);hands_value.name="HandsValue";controls.add_child(hands_value)
	hands_up=W.IconButton.new("plus","",22);hands_up.name="HandsUp";controls.add_child(hands_up);hands_up.pressed.connect(func():screen.act(int(view.id),"hands",float(view.hands_step)))
	hands_five=W.text_button("+5","Add five makers",false,24);hands_five.name="HandsFive";controls.add_child(hands_five);hands_five.pressed.connect(func():screen.act(int(view.id),"hands",5.0*float(view.hands_step)))
	controls.add_child(Folio.label("Target", "small", LIGHT))
	keep_down=W.IconButton.new("minus","",22);keep_down.name="KeepDown";controls.add_child(keep_down);keep_down.pressed.connect(func():screen.act(int(view.id),"target",float(Plain.step_target(int(view.target),-1))))
	keep_value=Folio.label("","small",LIGHT);keep_value.name="KeepValue";controls.add_child(keep_value)
	keep_up=W.IconButton.new("plus","",22);keep_up.name="KeepUp";controls.add_child(keep_up);keep_up.pressed.connect(func():screen.act(int(view.id),"target",float(Plain.step_target(int(view.target),1))))
	# Retain detail-only readings without making every row a full-page card.
	badge=W.Chip.new();badge.name="Badge";top.add_child(badge);top.move_child(badge,2)
	auto=W.text_button("Auto","");auto.name="Auto";controls.add_child(auto);auto.pressed.connect(func():screen.act(int(view.id),"auto",0.0 if bool(view.managed) else 1.0))
	skill=W.SkillGraph.new();skill.name="Skill";skill.visible=false;column.add_child(skill)
	target_row=Pictures.TargetRow.new();target_row.visible=false;column.add_child(target_row)
	apply(first)

func apply(next:Dictionary)->void:
	view=next
	var id:=int(view.id)
	var persistent:=bool(view.persistent)
	var paused:=bool(view.paused)
	var look:=String(view.look)
	var tone:={"good":T.GREEN,"warn":T.AMBER,"bad":T.RED}.get(look,T.RULE_STRONG) as Color
	var style:=Industrial.flat(OLIVE,Color("59604b"),1,1)
	style.content_margin_top=5;style.content_margin_bottom=5
	style.content_margin_left=6;style.content_margin_right=6
	add_theme_stylebox_override("panel",style)
	_left_rule=Color.TRANSPARENT;queue_redraw()
	var condition:=find_child("Condition",true,false) as Label
	condition.text=String(view.get("short","Working"))
	if condition.text.begins_with("Short of ") and float(view.get("rate",0))>0.0:
		condition.text=condition.text.trim_prefix("Short of ").capitalize()+" won't cover the target"
	condition.add_theme_color_override("font_color",T.text_for(tone) if look in ["bad","warn"] else T.INK_MUTED)
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
	close.tooltip_text=_close_tip()
	if not _arm_close:close.set_glyph("close")
	picture.texture=Folio.product_texture(String(view.item))
	var deficit:=int(view.get("deficit",0))
	stock.text=str(int(view.stock))
	stock.add_theme_color_override("font_color",T.RED_TEXT if deficit>0 else T.INK)
	var need:=int(view.get("needed",0))
	(picture.get_parent() as Control).tooltip_text="%d in store" % int(view.stock)+(", %d needed by the bands: short %d." % [need,deficit] if deficit>0 else (", %d needed by the bands." % need if need>0 else "."))
	bar.set_reading(float(view.next),look,daily_rate(float(view.rate)) if float(view.rate)>0 else String(view.bar_text),String(view.tip))
	var step:=float(view.hands_step)
	var people:=int(view.hands)
	hands_value.text=str(people)
	var total:=int(view.get("hands_total",0))
	if people>0:hands_value.tooltip_text="%d of your %d craftspeople work this line." % [people,total]
	elif float(view.get("hands_exact",0.0))>.05:hands_value.tooltip_text="No one works this line full time; it gets odd moments of the other hands' day. Add a hand to give it one."
	else:hands_value.tooltip_text="No hands on this line."
	var step_words:=Plain.hands_text(step)+(" hand" if is_equal_approx(step,1.0) else " hands")
	hands_down.tooltip_text="Take %s off; they go back to household crafting." % step_words
	hands_up.tooltip_text="Add %s: from household crafting, or from the lowest line when every craftsperson is busy." % step_words
	hands_five.tooltip_text="Add %s hands at once." % Plain.hands_text(step*5.0)
	for button:Button in [hands_down,hands_up,hands_five]:button.disabled=paused or total<=0
	hands_down.disabled=hands_down.disabled or people<=0
	if paused:
		for button:Button in [hands_up,hands_five]:button.tooltip_text="Resume the line to put hands on it."
	if keep_value!=null and not persistent:
		keep_value.text="%d/%d" % [int(view.get("completed",0)),int(view.get("ordered",0))]
		keep_value.tooltip_text="One-off order: "+String(view.get("progress_text",""))+"."
		keep_down.disabled=true;keep_up.disabled=true
		keep_down.tooltip_text="A one-off order has a fixed count.";keep_up.tooltip_text=keep_down.tooltip_text
	elif keep_value!=null:
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
	var keep_count:=int(view.get("target",0)) if persistent else int(view.get("ordered",0))
	var have:=int(view.stock) if persistent else int(view.get("completed",0))
	target_row.visible=false
	target_row.set_row(have,keep_count,float(view.get("next",0.0)) if not paused else 0.0,tone)
	target_row.tooltip_text=("%d in store of %d to keep; the open marks are still to make, the arc is the next one." % [have,keep_count]) if persistent else ("%d of %d made." % [have,keep_count])
	var factor:=clampf(float(view.get("resource_factor",1.0)),0,1)
	shortage.text="Inputs −%d%%" % roundi((1.0-factor)*100) if factor<.999 else "Inputs ✓"
	shortage.add_theme_color_override("font_color",Color("ef9c86") if factor<.999 else Color("b9d38c"))
	shortage.tooltip_text="Resource shortage reduces output by %d%%. Each missing input unit costs 5%% per capacity slot; 20 stops that slot. Priority runs top to bottom." % roundi((1-factor)*100)
	for resource:String in view.get("resource_missing",{}):
		if float(view.resource_missing[resource])>0:shortage.tooltip_text+="\n%s: %.1f capacity inputs short" % [resource,float(view.resource_missing[resource])]
	efficiency_bar.value=float(view.efficiency)*100;efficiency_bar.tooltip_text="Production efficiency: %d%%. %s" % [roundi(efficiency_bar.value),String(view.skill_tip)]
	var scale:=maxi(1,ceili(float(total)/15.0))
	for index in capacity_grid.get_child_count():
		var slot:Button=capacity_grid.get_child(index)
		var assigned:=index*scale<people
		(slot as CapacitySlot).lit=assigned
		(slot as CapacitySlot).blocked=assigned and factor<=0
		slot.queue_redraw()
		slot.add_theme_stylebox_override("normal",Industrial.flat(Color("252b22"),Color("414b36"),1,0))
		slot.add_theme_stylebox_override("hover",Industrial.flat(Color("c4c890"),Color("e5dfb6"),1,1))
		slot.tooltip_text="Assign %d makers to this line (%d per square)." % [mini(total,(index+1)*scale),scale]
		slot.disabled=paused or index*scale>=total
		slot.add_theme_stylebox_override("disabled",Industrial.flat(Color("20241e"),Color("424837"),1,1))
	condition.text="%d%% efficiency · %s" % [roundi(float(view.efficiency)*100),"Input shortage" if factor<.999 else "Producing" if float(view.rate)>0 else String(view.get("short","Waiting"))]
	condition.add_theme_color_override("font_color",LIGHT)
	title.add_theme_color_override("font_color",LIGHT)
	stock.add_theme_color_override("font_color",LIGHT)
	preload("res://scripts/hud/production_skin.gd").apply(self)
	tooltip_text=""

func _draw()->void:
	# The line's condition, as a rule down its left edge.
	if _left_rule.a>0.0:draw_rect(Rect2(Vector2.ZERO,Vector2(4,size.y)),_left_rule)

func _close_tip()->String:
	if bool(view.get("persistent",true)):return "Close this line. Finished goods stay in store; work in progress is lost."
	return "Cancel this one-off order. Finished items stay in store; unused materials come back."

func _on_close()->void:
	if not _arm_close:
		_arm_close=true;close.set_glyph("close","Click again to close this line.");close.danger=true
		close.add_theme_stylebox_override("normal",Industrial.flat(T.DANGER_BG,T.DANGER_BORDER,1,T.RADIUS_CONTROL))
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(self):
				_arm_close=false;close.restyle();close.tooltip_text=_close_tip())
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

static func daily_rate(value:float)->String:
	return ("%.3f" % value if value<.01 else "%.2f" % value)+" / day"


class CapacitySlot extends Button:
	var lit:=false
	var blocked:=false
	func _draw()->void:
		var ink:=Color("a2b66e") if lit else Color("555f47")
		if blocked:ink=Color("bd6550")
		var at:=Vector2(floorf((size.x-12)/2),floorf((size.y-10)/2))
		draw_colored_polygon(PackedVector2Array([at+Vector2(0,10),at+Vector2(0,5),at+Vector2(4,2),at+Vector2(4,5),at+Vector2(8,2),at+Vector2(8,5),at+Vector2(10,5),at+Vector2(10,0),at+Vector2(12,0),at+Vector2(12,10)]),ink)
		for x in [2,6,10]:draw_rect(Rect2(at+Vector2(x,7),Vector2(1,2)),Color("252b22"))
