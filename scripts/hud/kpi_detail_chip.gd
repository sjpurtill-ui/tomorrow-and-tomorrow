extends Button
const Data=preload("res://scripts/hud/kpi_detail_data.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
var metric_id:String
func _make_custom_tooltip(_text:String)->Object:
	return detail_panel(Data.snapshot(metric_id))
func detail_panel(data:Dictionary)->PanelContainer:
	var panel:=PanelContainer.new()
	panel.name="KpiDetailPanel"
	panel.theme=T.control_theme()
	panel.custom_minimum_size.x=clampf(get_viewport_rect().size.x-32,260,420)
	var style:=T.flat(T.DOCK_BG,T.BORDER,1,6,20)
	style.shadow_color=Color(0,0,0,.24);style.shadow_size=12;style.shadow_offset=Vector2(0,5)
	panel.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	column.add_child(T.make_label(String(data.scope).to_upper(),11,T.GOLD))
	column.add_child(T.make_label(String(data.title),20,T.INK))
	var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",12);column.add_child(hero)
	hero.add_child(T.make_label(String(data.value),38,T.INK))
	var unit:=T.make_label(String(data.unit),12,T.MUTED);unit.size_flags_horizontal=Control.SIZE_EXPAND_FILL;unit.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;unit.size_flags_vertical=Control.SIZE_SHRINK_CENTER;hero.add_child(unit)
	var accent:Color=T.RED if data.tone=="warning" else T.TEAL if data.tone=="good" else T.GOLD
	var status:=PanelContainer.new();status.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,accent,1,3,10));column.add_child(status)
	var note:=T.make_label(String(data.status),13,T.BODY);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_child(note)
	for item:Dictionary in data.rows:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);column.add_child(row)
		var label:=T.make_label(String(item.label),12,T.MUTED);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;row.add_child(label)
		var value:=T.make_label(String(item.value),13,T.INK);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(value)
	if float(data.meter)>=0:
		var label:=T.make_label("%s · %d%%" % [data.meter_label,roundi(float(data.meter)*100)],12,T.BODY);column.add_child(label)
		var bar:=ProgressBar.new();bar.custom_minimum_size.y=7;bar.show_percentage=false;bar.value=float(data.meter)*100
		bar.add_theme_stylebox_override("background",T.flat(T.TRACK));bar.add_theme_stylebox_override("fill",T.flat(accent));column.add_child(bar)
	var divider:=HSeparator.new();column.add_child(divider)
	column.add_child(T.make_label(String(data.footer),11,T.MUTED))
	return panel
