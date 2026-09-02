extends PanelContainer
## The reusable Dock: header (eyebrow/title/ESC/close), three sub-tabs, a
## four-tile KPI row, a decision brief with one direct action, and a scrolling
## body of DockBlocks. One instance serves all six sections; a second instance
## serves deep-detail views at x:652.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Blocks:=preload("res://scripts/hud/dock_blocks.gd")

signal close_requested
signal tab_changed(sub:int)

var provider:Object
var sub:int=0

var eyebrow_label:Label
var title_label:Label
var tab_buttons:Array[Button]=[]
var kpi_row:GridContainer
var brief_panel:PanelContainer
var body_scroll:ScrollContainer
var body:VBoxContainer

func _ready()->void:
	name="DockPanel" if name=="" or String(name).begins_with("@") else name
	add_theme_stylebox_override("panel",Tokens.dock_style())
	clip_contents=true
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",0)
	add_child(root)
	# Header
	var header:=MarginContainer.new()
	header.add_theme_constant_override("margin_left",18)
	header.add_theme_constant_override("margin_right",18)
	header.add_theme_constant_override("margin_top",14)
	header.add_theme_constant_override("margin_bottom",10)
	root.add_child(header)
	var header_row:=HBoxContainer.new()
	header_row.add_theme_constant_override("separation",10)
	header.add_child(header_row)
	var title_column:=VBoxContainer.new()
	title_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title_column.add_theme_constant_override("separation",2)
	header_row.add_child(title_column)
	eyebrow_label=Tokens.make_label("",10,Tokens.GOLD,0.14)
	title_column.add_child(eyebrow_label)
	title_label=Tokens.make_label("",21,Tokens.INK)
	title_column.add_child(title_label)
	var esc_hint:=Tokens.make_label("ESC",10,Tokens.DISABLED)
	esc_hint.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header_row.add_child(esc_hint)
	var close:=Button.new()
	close.name="DockClose"
	close.text="×"
	close.custom_minimum_size=Vector2(30,30)
	close.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	close.add_theme_font_size_override("font_size",14)
	close.add_theme_color_override("font_color",Tokens.TEXT_DIM)
	close.add_theme_stylebox_override("normal",Tokens.flat(Color(0,0,0,0),Tokens.BORDER_2,1,4))
	close.add_theme_stylebox_override("hover",Tokens.flat(Tokens.CLOSE_HOVER_BG,Tokens.BORDER_2,1,4))
	close.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	close.pressed.connect(func()->void: close_requested.emit())
	header_row.add_child(close)
	# Sub-tabs
	var tabs_margin:=MarginContainer.new()
	tabs_margin.add_theme_constant_override("margin_left",18)
	tabs_margin.add_theme_constant_override("margin_right",18)
	root.add_child(tabs_margin)
	var tabs_row:=HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation",2)
	tabs_margin.add_child(tabs_row)
	for index in 3:
		var tab:=Button.new()
		tab.custom_minimum_size=Vector2(0,28)
		tab.add_theme_font_size_override("font_size",10)
		tab.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		tab.pressed.connect(_on_tab_pressed.bind(index))
		tabs_row.add_child(tab)
		tab_buttons.append(tab)
	var tabs_rule:=ColorRect.new()
	tabs_rule.color=Tokens.BORDER
	tabs_rule.custom_minimum_size=Vector2(0,1)
	root.add_child(tabs_rule)
	# KPI row
	var kpi_margin:=MarginContainer.new()
	kpi_margin.add_theme_constant_override("margin_left",18)
	kpi_margin.add_theme_constant_override("margin_right",18)
	kpi_margin.add_theme_constant_override("margin_top",12)
	root.add_child(kpi_margin)
	kpi_row=GridContainer.new()
	kpi_row.columns=4
	kpi_row.add_theme_constant_override("h_separation",8)
	kpi_margin.add_child(kpi_row)
	# Decision brief
	var brief_margin:=MarginContainer.new()
	brief_margin.add_theme_constant_override("margin_left",18)
	brief_margin.add_theme_constant_override("margin_right",18)
	brief_margin.add_theme_constant_override("margin_top",10)
	root.add_child(brief_margin)
	brief_panel=PanelContainer.new()
	brief_margin.add_child(brief_panel)
	# Body
	body_scroll=ScrollContainer.new()
	body_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(body_scroll)
	var body_margin:=MarginContainer.new()
	body_margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left",18)
	body_margin.add_theme_constant_override("margin_right",18)
	body_margin.add_theme_constant_override("margin_top",12)
	body_margin.add_theme_constant_override("margin_bottom",18)
	body_scroll.add_child(body_margin)
	body=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14)
	body_margin.add_child(body)


func present(new_provider:Object,new_sub:int=0)->void:
	provider=new_provider
	sub=clampi(new_sub,0,2)
	rebuild()


func rebuild()->void:
	if provider==null: return
	var meta:Dictionary=provider.meta()
	eyebrow_label.text=String(meta.get("eyebrow",""))
	title_label.text=String(meta.get("title",""))
	var subtabs:Array=meta.get("subtabs",[])
	for index in tab_buttons.size():
		var tab:=tab_buttons[index]
		tab.visible=index<subtabs.size()
		if index<subtabs.size(): tab.text=String(subtabs[index])
		var active:=index==sub
		var style:=Tokens.flat(Tokens.ACTIVE_BG if active else Color(0,0,0,0),Tokens.BORDER,1,3)
		style.border_width_bottom=0
		style.corner_radius_bottom_left=0
		style.corner_radius_bottom_right=0
		style.content_margin_left=12.0
		style.content_margin_right=12.0
		tab.add_theme_stylebox_override("normal",style)
		tab.add_theme_stylebox_override("hover",style)
		tab.add_theme_stylebox_override("pressed",style)
		tab.add_theme_color_override("font_color",Tokens.INK if active else Tokens.MUTED)
		tab.add_theme_color_override("font_hover_color",Tokens.INK)
	rebuild_body()


func rebuild_body()->void:
	if provider==null: return
	var data:Dictionary=provider.tab(sub)
	_rebuild_kpis(data.get("kpis",[]))
	_rebuild_brief(data.get("brief",{}))
	var scroll_position:=body_scroll.scroll_vertical
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	Blocks.render(body,data.get("blocks",[]))
	body_scroll.scroll_vertical=scroll_position


func _rebuild_kpis(kpis:Array)->void:
	for child in kpi_row.get_children():
		kpi_row.remove_child(child)
		child.queue_free()
	for kpi_variant in kpis:
		var kpi:Dictionary=kpi_variant
		var tile:=PanelContainer.new()
		tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",Tokens.tile_style(kpi.get("accent",Tokens.TEAL)))
		tile.tooltip_text=String(kpi.get("tip",""))
		kpi_row.add_child(tile)
		var column:=VBoxContainer.new()
		column.add_theme_constant_override("separation",1)
		tile.add_child(column)
		column.add_child(Tokens.make_label(String(kpi.get("label","")),9,Tokens.MUTED,0.1))
		var value_row:=HBoxContainer.new()
		value_row.add_theme_constant_override("separation",6)
		column.add_child(value_row)
		value_row.add_child(Tokens.make_label(String(kpi.get("value","")),18,Tokens.INK))
		if String(kpi.get("delta",""))!="":
			var delta:=Tokens.make_label(String(kpi.delta),10,kpi.get("delta_color",Tokens.MUTED))
			delta.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
			value_row.add_child(delta)


func _rebuild_brief(brief:Dictionary)->void:
	for child in brief_panel.get_children():
		brief_panel.remove_child(child)
		child.queue_free()
	brief_panel.visible=not brief.is_empty()
	if brief.is_empty(): return
	brief_panel.add_theme_stylebox_override("panel",Tokens.brief_style(String(brief.get("tone","info"))))
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	brief_panel.add_child(row)
	var text_column:=VBoxContainer.new()
	text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation",2)
	row.add_child(text_column)
	text_column.add_child(Tokens.make_label(String(brief.get("title","")),12,Tokens.INK))
	var why:=Tokens.make_label(String(brief.get("why","")),11,Tokens.TEXT_SOFT)
	why.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(why)
	if String(brief.get("action_label",""))!="":
		var action:=Button.new()
		action.name="BriefAction"
		action.text=String(brief.action_label)
		action.custom_minimum_size=Vector2(0,28)
		action.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		action.add_theme_font_size_override("font_size",10)
		action.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT)
		action.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
		action.add_theme_stylebox_override("hover",Tokens.gold_outline_style())
		action.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		var on_action:Variant=brief.get("on_action")
		if on_action is Callable:
			action.pressed.connect(on_action)
		row.add_child(action)


func _on_tab_pressed(index:int)->void:
	if index==sub: return
	sub=index
	rebuild()
	tab_changed.emit(sub)
	# 100 ms content crossfade per the design spec.
	body_scroll.modulate=Color(1,1,1,0)
	create_tween().tween_property(body_scroll,"modulate:a",1.0,0.1)
