class_name DockBlocks
## Renders the nine dock body block types from plain dictionaries. Interactive
## items carry Callables ("on_press", "on_minus", "on_plus", "on_click",
## "on_submit"). Block shape reference: design handoff Dock Panel.dc.html.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")


static func render(container:VBoxContainer,blocks:Array)->void:
	for block_variant in blocks:
		var block:Dictionary=block_variant
		var section:=VBoxContainer.new()
		section.add_theme_constant_override("separation",6)
		container.add_child(section)
		if String(block.get("heading",""))!="":
			var heading_row:=HBoxContainer.new()
			section.add_child(heading_row)
			var heading:=Tokens.make_label(String(block.heading),10,Tokens.GOLD,0.1)
			heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			heading_row.add_child(heading)
			if String(block.get("note",""))!="":
				var note:=Tokens.make_label(String(block.note),10,Tokens.MUTED)
				note.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
				heading_row.add_child(note)
		match String(block.get("type","text")):
			"segments": _render_segments(section,block)
			"alloc": _render_alloc(section,block)
			"bars": _render_bars(section,block)
			"tiles": _render_tiles(section,block)
			"rows": _render_rows(section,block)
			"caps": _render_caps(section,block)
			"actions": _render_actions(section,block)
			"order": _render_order(section,block)
			_: _render_text(section,block)


static func _render_segments(parent:VBoxContainer,block:Dictionary)->void:
	var bar:=HBoxContainer.new()
	bar.custom_minimum_size=Vector2(0,36)
	bar.add_theme_constant_override("separation",2)
	parent.add_child(bar)
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var segment:=ColorRect.new()
		segment.color=item.get("color",Tokens.MUTED)
		segment.custom_minimum_size=Vector2(24,36)
		segment.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		segment.size_flags_stretch_ratio=maxf(0.05,float(item.get("share",1.0)))
		segment.tooltip_text=String(item.get("tip",""))
		segment.mouse_filter=Control.MOUSE_FILTER_STOP
		bar.add_child(segment)
		var stack:=VBoxContainer.new()
		stack.set_anchors_preset(Control.PRESET_FULL_RECT)
		stack.alignment=BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation",0)
		stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
		segment.add_child(stack)
		var count:=Tokens.make_label(String(item.get("value","")),12,Tokens.GLYPH_DARK)
		count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		count.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.add_child(count)
		var caption:=Tokens.make_label(String(item.get("label","")),9,Tokens.GLYPH_DARK)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		stack.add_child(caption)
	if String(block.get("legend",""))!="":
		parent.add_child(Tokens.make_label(String(block.legend),10,Tokens.MUTED))


static func _render_alloc(parent:VBoxContainer,block:Dictionary)->void:
	var items:Array=block.get("items",[])
	var share_bar:=HBoxContainer.new()
	share_bar.custom_minimum_size=Vector2(0,6)
	share_bar.add_theme_constant_override("separation",0)
	parent.add_child(share_bar)
	var total:=0.0
	for item_variant in items: total+=maxf(0.0,float((item_variant as Dictionary).get("count",0)))
	for item_variant in items:
		var item:Dictionary=item_variant
		var slice:=ColorRect.new()
		slice.color=item.get("color",Tokens.MUTED)
		slice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		slice.size_flags_stretch_ratio=maxf(0.01,float(item.get("count",0)))
		share_bar.add_child(slice)
	if total<=0.0:
		var empty:=ColorRect.new()
		empty.color=Tokens.TRACK
		empty.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		share_bar.add_child(empty)
	for item_variant in items:
		var item:Dictionary=item_variant
		var row:=HBoxContainer.new()
		row.custom_minimum_size=Vector2(0,28)
		row.add_theme_constant_override("separation",8)
		row.tooltip_text=String(item.get("tip",""))
		parent.add_child(row)
		var swatch:=ColorRect.new()
		swatch.color=item.get("color",Tokens.MUTED)
		swatch.custom_minimum_size=Vector2(10,10)
		swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(swatch)
		var name_label:=Tokens.make_label(String(item.get("name","")),12,Tokens.BODY)
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.tooltip_text=String(item.get("tip",""))
		row.add_child(name_label)
		if String(item.get("pct",""))!="":
			row.add_child(Tokens.make_label(String(item.pct),10,Tokens.MUTED))
		var count_label:=Tokens.make_label(str(int(item.get("count",0))),13,Tokens.INK)
		count_label.custom_minimum_size=Vector2(40,0)
		count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(count_label)
		row.add_child(_step_button("−",item.get("on_minus"),String(item.get("tip",""))))
		row.add_child(_step_button("+",item.get("on_plus"),String(item.get("tip",""))))


static func _step_button(glyph:String,action:Variant,tip:String)->Button:
	var button:=Button.new()
	button.text=glyph
	button.custom_minimum_size=Vector2(26,24)
	button.tooltip_text=tip
	button.add_theme_font_size_override("font_size",12)
	button.add_theme_color_override("font_color",Tokens.TEXT_DIM)
	button.add_theme_stylebox_override("normal",Tokens.flat(Tokens.BUTTON_BG,Tokens.BORDER_2,1,3))
	button.add_theme_stylebox_override("hover",Tokens.flat(Tokens.BUTTON_BG,Tokens.GOLD,1,3))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	if action is Callable:
		button.pressed.connect(action)
	else:
		button.disabled=true
	return button


static func _render_bars(parent:VBoxContainer,block:Dictionary)->void:
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var color:Color=item.get("color",Tokens.TEAL)
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		row.tooltip_text=String(item.get("tip",""))
		parent.add_child(row)
		var name_label:=Tokens.make_label(String(item.get("name","")),11,Tokens.BODY_2)
		name_label.custom_minimum_size=Vector2(130,0)
		name_label.clip_text=true
		row.add_child(name_label)
		var track:=ColorRect.new()
		track.color=Tokens.TRACK
		track.custom_minimum_size=Vector2(0,8)
		track.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		track.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		row.add_child(track)
		var fill:=ColorRect.new()
		fill.color=color
		fill.anchor_right=clampf(float(item.get("ratio",0.0)),0.0,1.0)
		fill.anchor_bottom=1.0
		fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)
		var value_label:=Tokens.make_label(String(item.get("value","")),12,color)
		value_label.custom_minimum_size=Vector2(72,0)
		value_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)


static func _render_tiles(parent:VBoxContainer,block:Dictionary)->void:
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	parent.add_child(grid)
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var tile:=PanelContainer.new()
		tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",Tokens.tile_style())
		tile.tooltip_text=String(item.get("tip",""))
		grid.add_child(tile)
		var column:=VBoxContainer.new()
		column.add_theme_constant_override("separation",2)
		tile.add_child(column)
		column.add_child(Tokens.make_label(String(item.get("label","")),9,Tokens.MUTED,0.1))
		column.add_child(Tokens.make_label(String(item.get("value","")),18,Tokens.INK))
		if String(item.get("note",""))!="":
			column.add_child(Tokens.make_label(String(item.note),11,item.get("note_color",Tokens.MUTED)))


static func _render_rows(parent:VBoxContainer,block:Dictionary)->void:
	var list:=VBoxContainer.new()
	list.add_theme_constant_override("separation",4)
	parent.add_child(list)
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var row:=PanelContainer.new()
		row.add_theme_stylebox_override("panel",Tokens.row_style(item.get("accent",Color(0,0,0,0))))
		row.tooltip_text=String(item.get("tip",""))
		list.add_child(row)
		var inner:=HBoxContainer.new()
		inner.add_theme_constant_override("separation",10)
		row.add_child(inner)
		var text_column:=VBoxContainer.new()
		text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		text_column.add_theme_constant_override("separation",1)
		inner.add_child(text_column)
		var name_label:=Tokens.make_label(String(item.get("name","")),12,Tokens.INK)
		name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		text_column.add_child(name_label)
		if String(item.get("sub",""))!="":
			var sub_label:=Tokens.make_label(String(item.sub),11,Tokens.MUTED)
			sub_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			text_column.add_child(sub_label)
		if String(item.get("value",""))!="":
			var value_label:=Tokens.make_label(String(item.value),12,item.get("value_color",Tokens.BODY_2))
			value_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			inner.add_child(value_label)
		var action:Variant=item.get("on_click")
		if action is Callable:
			row.mouse_filter=Control.MOUSE_FILTER_STOP
			row.gui_input.connect(func(event:InputEvent)->void:
				var mouse:=event as InputEventMouseButton
				if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
					(action as Callable).call())


static func _render_caps(parent:VBoxContainer,block:Dictionary)->void:
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",4)
	parent.add_child(grid)
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var pct:=clampf(float(item.get("pct",0.0)),0.0,100.0)
		var color:=Tokens.capacity_color(pct)
		var cell:=VBoxContainer.new()
		cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation",2)
		cell.tooltip_text=String(item.get("tip",""))
		grid.add_child(cell)
		var top:=HBoxContainer.new()
		top.add_theme_constant_override("separation",6)
		cell.add_child(top)
		var name_label:=Tokens.make_label(String(item.get("name","")),11,Tokens.BODY_2)
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.tooltip_text=String(item.get("tip",""))
		top.add_child(name_label)
		var trend:=String(item.get("trend","—"))
		var trend_color:=Tokens.GREEN if trend=="▲" else (Tokens.RED if trend=="▼" else Tokens.MUTED)
		top.add_child(Tokens.make_label(trend,10,trend_color))
		var pct_label:=Tokens.make_label("%d%%" % roundi(pct),13,color)
		pct_label.custom_minimum_size=Vector2(34,0)
		pct_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		top.add_child(pct_label)
		var track:=ColorRect.new()
		track.color=Tokens.TRACK
		track.custom_minimum_size=Vector2(0,5)
		cell.add_child(track)
		var fill:=ColorRect.new()
		fill.color=color
		fill.anchor_right=pct/100.0
		fill.anchor_bottom=1.0
		fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)


static func _render_actions(parent:VBoxContainer,block:Dictionary)->void:
	var grid:=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	parent.add_child(grid)
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var primary:=bool(item.get("primary",false))
		var disabled:=bool(item.get("disabled",false))
		var button:=Button.new()
		button.custom_minimum_size=Vector2(0,38)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.disabled=disabled
		button.tooltip_text=String(item.get("tip",""))
		button.add_theme_stylebox_override("normal",Tokens.action_button_style(primary))
		button.add_theme_stylebox_override("hover",Tokens.action_button_style(primary,true))
		button.add_theme_stylebox_override("disabled",Tokens.action_button_style(false))
		button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		grid.add_child(button)
		var column:=VBoxContainer.new()
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.alignment=BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation",1)
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(column)
		var fg:=Tokens.DISABLED if disabled else (Tokens.GOLD_BRIGHT if primary else Tokens.BODY)
		var label:=Tokens.make_label(String(item.get("label","")),11,fg,0.06)
		label.clip_text=true
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
		if String(item.get("sub",""))!="":
			var sub_label:=Tokens.make_label(String(item.sub),10,Tokens.MUTED)
			sub_label.clip_text=true
			sub_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
			column.add_child(sub_label)
		var action:Variant=item.get("on_press")
		if action is Callable and not disabled:
			button.pressed.connect(action)


static func _render_text(parent:VBoxContainer,block:Dictionary)->void:
	var body:=Tokens.make_label(String(block.get("text","")),12,Tokens.TEXT_SOFT)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(body)


static func _render_order(parent:VBoxContainer,block:Dictionary)->void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	parent.add_child(row)
	var field:=LineEdit.new()
	field.name="SovereignOrderInput"
	field.placeholder_text=String(block.get("placeholder","Issue a sovereign order…"))
	field.custom_minimum_size=Vector2(0,38)
	field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	field.add_theme_font_size_override("font_size",12)
	field.add_theme_color_override("font_color",Tokens.BODY)
	field.add_theme_color_override("font_placeholder_color",Tokens.DISABLED)
	field.add_theme_stylebox_override("normal",Tokens.flat(Tokens.FIELD_BG,Tokens.BORDER_2,1,3,8.0))
	field.add_theme_stylebox_override("focus",Tokens.flat(Tokens.FIELD_BG,Tokens.GOLD,1,3,8.0))
	row.add_child(field)
	var issue:=Button.new()
	issue.name="SovereignOrderIssue"
	issue.text="ISSUE"
	issue.custom_minimum_size=Vector2(0,38)
	issue.add_theme_font_size_override("font_size",11)
	issue.add_theme_color_override("font_color",Tokens.GOLD_BRIGHT)
	issue.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
	issue.add_theme_stylebox_override("hover",Tokens.gold_outline_style())
	issue.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	row.add_child(issue)
	var submit:Variant=block.get("on_submit")
	if submit is Callable:
		issue.pressed.connect(func()->void: (submit as Callable).call(field))
		field.text_submitted.connect(func(_text:String)->void: (submit as Callable).call(field))
	if String(block.get("helper",""))!="":
		var helper:=Tokens.make_label(String(block.helper),10,Tokens.MUTED)
		helper.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(helper)
	if String(block.get("status",""))!="":
		var status:=Tokens.make_label(String(block.status),10,block.get("status_color",Tokens.MUTED))
		status.name="SovereignOrderStatus"
		status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(status)
