class_name DockBlocks
## Renders the nine dock body block types from plain dictionaries. Interactive
## items carry Callables ("on_press", "on_minus", "on_plus", "on_click",
## "on_submit"). Block shape reference: design handoff Dock Panel.dc.html.

const Live:=preload("res://scripts/hud/live_value_binding.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const HealthHistoryChart:=preload("res://scripts/hud/health_history_chart.gd")
const ExpeditionChart:=preload("res://scripts/hud/expedition_chart.gd")
const ResearchVisuals:=preload("res://scripts/hud/research_visuals.gd")


static func render(container:VBoxContainer,blocks:Array)->void:
	for block_variant in blocks:
		var block:Dictionary=block_variant
		var section:=VBoxContainer.new()
		section.add_theme_constant_override("separation",6)
		container.add_child(section)
		if String(block.get("heading",""))!="":
			var heading_row:=HBoxContainer.new()
			section.add_child(heading_row)
			var heading:=Tokens.make_label(Tokens.sentence_case(String(block.heading)),12,Tokens.GOLD_TEXT,0.06)
			heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			heading_row.add_child(heading)
			if String(block.get("note",""))!="":
				var note:=Tokens.make_label(String(block.note),12,Tokens.MUTED)
				note.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
				heading_row.add_child(note)
		match String(block.get("type","text")):
			"known_world":
				var board:=preload("res://scripts/hud/known_world_board.gd").new();section.add_child(board);board.setup(block)
			"peoples_known":
				var board:=preload("res://scripts/hud/peoples_known_board.gd").new();section.add_child(board);board.setup(block)
			"city_dossier":
				var dossier:=preload("res://scripts/hud/city_dossier.gd").new();section.add_child(dossier);dossier.setup(block)
			"held_town":
				var held:=preload("res://scripts/hud/held_town_dossier.gd").new();section.add_child(held);held.setup(block)
			"standing":
				var board:=preload("res://scripts/hud/standing_board.gd").new();section.add_child(board);board.setup(block)
			"culture":
				var panel:=preload("res://scripts/hud/culture_panel.gd").new();section.add_child(panel);panel.setup(block)
			"people":
				var screen:=preload("res://scripts/hud/people_screen.gd").new();section.add_child(screen);screen.setup(block)
			"settlement_overview":
				var panel:=preload("res://scripts/hud/overview_folio.gd").new();section.add_child(panel);panel.setup(block)
			"chronicle":
				var panel:=preload("res://scripts/hud/settlement_chronicle.gd").new();section.add_child(panel);panel.setup(block)
			"chronicle_feed":
				var feed:=preload("res://scripts/hud/chronicle_feed.gd").new();section.add_child(feed);feed.setup(block)
			"purse_board":
				var board:=preload("res://scripts/hud/purse_board.gd").new();section.add_child(board);board.setup(block)
			"wealth_ledger":
				var panel:=preload("res://scripts/hud/wealth_ledger.gd").new()
				section.add_child(panel);panel.setup(block)
			"materials_ledger":
				var panel:=preload("res://scripts/hud/materials_ledger.gd").new()
				section.add_child(panel);panel.setup(block)
			"trade_board":
				var trade:=preload("res://scripts/hud/trade_board.gd").new();section.add_child(trade);trade.setup(block)
			"provisions":
				var panel:=preload("res://scripts/hud/provisions_panel.gd").new()
				section.add_child(panel);panel.setup(block)
			"impact_lines":
				var impact:=preload("res://scripts/hud/impact_panel.gd").new()
				section.add_child(impact);impact.setup(block)
			"town_works":
				var works:=preload("res://scripts/hud/town_works_board.gd").new()
				section.add_child(works);works.setup(block)
			"construction_queue":
				var queue:=preload("res://scripts/hud/construction_queue.gd").new()
				section.add_child(queue);queue.setup(block)
			"production_queue":
				var queue:=preload("res://scripts/hud/production_queue.gd").new()
				section.add_child(queue);queue.setup(block)
			"production_line":
				var inspector:=preload("res://scripts/hud/production_line_detail.gd").new()
				section.add_child(inspector);inspector.setup(block)
			"production_board":
				var board:=preload("res://scripts/hud/production_board.gd").new()
				section.add_child(board);board.setup(block)
			"inquiry_board":
				var board:=preload("res://scripts/hud/inquiry_board.gd").new();section.add_child(board);board.setup(block)
			"field_sheet":
				var sheet:=preload("res://scripts/hud/field_sheet.gd").new();section.add_child(sheet);sheet.setup(block)
			"impact":
				var ledger:=preload("res://scripts/hud/impact_ledger.gd").new();section.add_child(ledger);ledger.setup(block)
			"recruit_deploy":
				var board:=preload("res://scripts/hud/recruit_deploy_board.gd").new()
				section.add_child(board);board.setup(block)
			"recruitment_brief":
				var brief:=preload("res://scripts/hud/recruitment_brief.gd").new()
				section.add_child(brief);brief.setup(block)
			"scout_archive":
				var archive:=preload("res://scripts/hud/scout_archive_widget.gd").new()
				archive.records=block.get("reports",[])
				archive.view_state=block.get("view_state",{})
				archive.open_report=block.get("on_open",Callable())
				section.add_child(archive)
			"trend_chart":
				var chart:=preload("res://scripts/hud/trend_chart.gd").new()
				section.add_child(chart)
				chart.setup(block)
			"expedition_chart":
				var chart:=ExpeditionChart.new()
				chart.route=block.get("route",[])
				chart.discoveries=block.get("discoveries",[])
				section.add_child(chart)
			"discovery": _render_discovery(section,block)
			"line_chart": _render_line_chart(section,block)
			"segments": _render_segments(section,block)
			"alloc": _render_alloc(section,block)
			"bars": _render_bars(section,block)
			"tiles": _render_tiles(section,block)
			"rows": _render_rows(section,block)
			"caps": _render_caps(section,block)
			"actions": _render_actions(section,block)
			# No talk or order boxes in a dock: every conversation happens in the
			# court (one-court-screen). Old "conversation"/"order" blocks render
			# as their plain text only.
			"image": _render_image(section,block)
			_: _render_text(section,block)


static func _render_discovery(parent:VBoxContainer,block:Dictionary)->void:
	var accent:Color=Tokens.TEAL if String(block.get("kind",""))=="resource" else Tokens.BLUE
	var frame:=PanelContainer.new()
	# Paper and ink, with the accent as a top rule (never a dark card).
	var style:=Tokens.flat(Tokens.PAPER_RAISED,Tokens.RULE,1,Tokens.RADIUS_CARD)
	style.border_color=accent;style.border_width_top=3
	style.content_margin_left=20; style.content_margin_right=20
	style.content_margin_top=16; style.content_margin_bottom=18
	frame.add_theme_stylebox_override("panel",style)
	parent.add_child(frame)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	frame.add_child(column)
	var heading:=String(block.get("kind","discovery")).capitalize()
	if block.has("distance_km"): heading+=" · %s km from home" % str(int(block.distance_km))
	column.add_child(Tokens.make_label(heading,12,Tokens.text_for(accent),0.06))
	var discovery_id:=String(block.get("discovery_id",""))
	if discovery_id!="":
		var definition:=DiscoverySystem.discovery_definition(discovery_id)
		# Full width at the painting's own proportions: wide banners show whole.
		if not definition.is_empty():ResearchVisuals.paint_hero(column,definition,110,220)
	var title:=Tokens.make_label(String(block.get("title","A new discovery")),23,Tokens.INK)
	var serif:Font=Tokens.voice_font()
	title.add_theme_font_override("font",serif)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	for key in ["description","consequence"]:
		var text:=String(block.get(key,""))
		if text.is_empty(): continue
		if key=="consequence": text="What this opens up: "+text
		var label:=Tokens.make_label(text,13 if key=="description" else 12,Tokens.BODY if key=="description" else Tokens.TEXT_SOFT)
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)

static func _render_line_chart(parent:VBoxContainer,block:Dictionary)->void:
	var chart:=HealthHistoryChart.new()
	# Optional shape of the line; without them the chart is the Health dock's.
	if block.has("value_key"): chart.value_key=String(block.value_key)
	if block.has("min_span"): chart.min_span=float(block.min_span)
	if block.has("floor"): chart.floor_value=float(block.floor)
	if block.has("ceiling"): chart.ceiling_value=float(block.ceiling)
	if block.get("describe") is Callable: chart.describe=block.describe
	chart.set_points(block.get("items",[]) as Array)
	chart.tooltip_text=String(block.get("tip","Hover the line to inspect a recorded month."))
	parent.add_child(chart)
	if block.get("legend") is Array:
		# The marks this chart uses, each drawn as the chart draws it.
		var keyed:=HFlowContainer.new()
		keyed.add_theme_constant_override("h_separation",14)
		keyed.add_theme_constant_override("v_separation",2)
		parent.add_child(keyed)
		for entry_variant in (block.legend as Array):
			var entry:Dictionary=entry_variant
			var pair:=HBoxContainer.new()
			pair.add_theme_constant_override("separation",5)
			pair.add_child(HealthHistoryChart.Glyph.new(String(entry.get("kind","")),float(entry.get("delta",0.0))))
			pair.add_child(Tokens.make_label(String(entry.get("text","")),12,Tokens.MUTED))
			keyed.add_child(pair)
		return
	var legend:=HBoxContainer.new()
	legend.add_theme_constant_override("separation",14)
	parent.add_child(legend)
	legend.add_child(Tokens.make_label("◆ a health discovery",12,Tokens.GOLD_TEXT))
	legend.add_child(Tokens.make_label("● living conditions changed",12,Tokens.MUTED))


static func _render_segments(parent:VBoxContainer,block:Dictionary)->void:
	var bar:=HBoxContainer.new()
	bar.custom_minimum_size=Vector2(0,14)
	bar.add_theme_constant_override("separation",2)
	parent.add_child(bar)
	var captions:=HBoxContainer.new()
	captions.add_theme_constant_override("separation",2)
	parent.add_child(captions)
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var segment:=ColorRect.new()
		segment.color=item.get("color",Tokens.MUTED)
		segment.custom_minimum_size=Vector2(24,14)
		segment.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		segment.size_flags_stretch_ratio=maxf(0.05,float(item.get("share",1.0)))
		segment.tooltip_text=String(item.get("tip",""))
		segment.mouse_filter=Control.MOUSE_FILTER_STOP
		bar.add_child(segment)
		# The count and caption sit on paper under their colour, in ink: cream
		# text on the cohort greens read at under 3.3:1.
		var key:=VBoxContainer.new()
		key.custom_minimum_size=Vector2(24,0)
		key.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		key.size_flags_stretch_ratio=segment.size_flags_stretch_ratio
		key.add_theme_constant_override("separation",0)
		key.mouse_filter=Control.MOUSE_FILTER_IGNORE
		captions.add_child(key)
		var count:=Tokens.make_label(String(item.get("value","")),12,Tokens.INK)
		count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		count.clip_text=true
		count.mouse_filter=Control.MOUSE_FILTER_IGNORE
		key.add_child(count)
		var caption:=Tokens.make_label(String(item.get("label","")),12,Tokens.MUTED)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.clip_text=true
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		key.add_child(caption)
	if String(block.get("legend",""))!="":
		var legend:=Tokens.make_label(String(block.legend),12,Tokens.MUTED)
		legend.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(legend)


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
			var pct_label:=Tokens.make_label(String(item.pct),12,Tokens.MUTED)
			row.add_child(pct_label)
			Live.attach(pct_label,"text",item.get("live_pct"))
		var count_label:=Tokens.make_label(String(item.count_text) if item.has("count_text") else str(int(item.get("count",0))),13,Tokens.INK)
		count_label.custom_minimum_size=Vector2(40,0)
		count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(count_label)
		if item.get("on_minus") is Callable or item.get("on_plus") is Callable:
			row.add_child(_step_button("Fewer",item.get("on_minus"),String(item.get("tip",""))))
			row.add_child(_step_button("More",item.get("on_plus"),String(item.get("tip",""))))


static func _step_button(glyph:String,action:Variant,tip:String)->Button:
	var button:=Button.new()
	button.text=glyph
	button.custom_minimum_size=Vector2(0,24)
	button.tooltip_text=tip
	button.add_theme_font_size_override("font_size",12)
	button.add_theme_color_override("font_color",Tokens.TEXT_DIM)
	button.add_theme_stylebox_override("normal",Tokens.flat(Tokens.BUTTON_BG,Tokens.BORDER_2,1,3))
	button.add_theme_stylebox_override("hover",Tokens.flat(Tokens.BUTTON_BG,Tokens.GOLD,1,3))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	if action is Callable:
		# An explicit press must show its result immediately. The passive
		# live-refresh guard skips rebuilds while the pointer hovers the dock,
		# so without this the changed value stays stale until the mouse leaves
		# — which reads as the click not registering.
		button.pressed.connect(func()->void:
			(action as Callable).call()
			_request_rebuild(button))
	else:
		button.disabled=true
	return button


static func _request_rebuild(from:Node)->void:
	## Deferred so the pressed button finishes its own handler before the body
	## it lives in is torn down and rebuilt. The action itself may have already
	## rebuilt or closed the dock, freeing the button.
	if not is_instance_valid(from): return
	var ancestor:Node=from
	while ancestor!=null and not ancestor.has_method("rebuild_body"):
		ancestor=ancestor.get_parent()
	if ancestor!=null: ancestor.call_deferred("rebuild_body")


static func _render_bars(parent:VBoxContainer,block:Dictionary)->void:
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		var color:Color=item.get("color",Tokens.TEAL)
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		row.tooltip_text=String(item.get("tip",""))
		parent.add_child(row)
		var name_label:=Tokens.make_label(String(item.get("name","")),12,Tokens.BODY_2)
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
		var value_label:=Tokens.make_label(String(item.get("value","")),12,Tokens.text_for(color))
		value_label.custom_minimum_size=Vector2(72,0)
		value_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)


static func _render_tiles(parent:VBoxContainer,block:Dictionary)->void:
	var grid:=GridContainer.new()
	grid.columns=clampi(int(block.get("columns",2)),1,3)
	if grid.columns==3:grid.resized.connect(func()->void:grid.columns=2 if grid.size.x<780 else 3)
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
		column.add_child(Tokens.make_label(String(item.get("label","")),12,Tokens.MUTED,0.06))
		column.add_child(Tokens.make_label(String(item.get("value","")),18,Tokens.INK))
		if String(item.get("note",""))!="":
			var note:=Tokens.make_label(String(item.note),12,Tokens.text_for(item.get("note_color",Tokens.MUTED)))
			note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			column.add_child(note)


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
		Live.attach(row,"tooltip_text",item.get("live_tip"))
		var inner:=HBoxContainer.new()
		inner.add_theme_constant_override("separation",10)
		row.add_child(inner)
		var icon_variant:Variant=item.get("icon")
		if icon_variant is Texture2D:
			var icon_rect:=TextureRect.new()
			icon_rect.texture=icon_variant
			icon_rect.custom_minimum_size=Vector2(24,24)
			icon_rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			icon_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
			inner.add_child(icon_rect)
		var text_column:=VBoxContainer.new()
		text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		text_column.add_theme_constant_override("separation",1)
		inner.add_child(text_column)
		var name_label:=Tokens.make_label(String(item.get("name","")),12,Tokens.INK)
		name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		text_column.add_child(name_label)
		Live.attach(name_label,"text",item.get("live_name"))
		if String(item.get("sub",""))!="":
			var sub_label:=Tokens.make_label(String(item.sub),12,Tokens.MUTED)
			sub_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			text_column.add_child(sub_label)
			Live.attach(sub_label,"text",item.get("live_sub"))
		if String(item.get("detail",""))!="":
			var detail_label:=Tokens.make_label(String(item.detail),12,Tokens.TEXT_SOFT)
			detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			text_column.add_child(detail_label)
			Live.attach(detail_label,"text",item.get("live_detail"))
		if String(item.get("value",""))!="":
			var value_label:=Tokens.make_label(String(item.value),12,Tokens.text_for(item.get("value_color",Tokens.BODY_2)))
			value_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			inner.add_child(value_label)
			Live.attach(value_label,"text",item.get("live_value"))
		var action:Variant=item.get("on_click")
		if action is Callable:
			# The complete row is one hit target. Nested containers must not swallow
			# clicks on the office name or APPOINT value before they reach the row.
			for child:Node in row.find_children("*","Control",true,false):
				(child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE
			row.mouse_filter=Control.MOUSE_FILTER_STOP
			row.focus_mode=Control.FOCUS_ALL
			row.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
			row.gui_input.connect(func(event:InputEvent)->void:
				var mouse:=event as InputEventMouseButton
				if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
					row.accept_event();(action as Callable).call()
				elif event.is_action_pressed("ui_accept"):
					row.accept_event();(action as Callable).call())


static func _render_caps(parent:VBoxContainer,block:Dictionary)->void:
	var grid:=GridContainer.new()
	grid.columns=clampi(int(block.get("columns",2)),1,2)
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",4)
	parent.add_child(grid)
	for item_variant in (block.get("items",[]) as Array):
		var item:Dictionary=item_variant
		# A row that carries its history, or opens it, is drawn as a history row.
		if item.has("history") or item.get("on_press") is Callable:
			grid.add_child(_capacity_row(item))
			continue
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
		var name_label:=Tokens.make_label(String(item.get("name","")),12,Tokens.BODY_2)
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.tooltip_text=String(item.get("tip",""))
		top.add_child(name_label)
		# The trend in a word, not a bare arrow.
		var trend:=String(item.get("trend","—"))
		var trend_word:="rising" if trend in ["▲","↑","up"] else "falling" if trend in ["▼","↓","down"] else ""
		if trend_word!="":
			top.add_child(Tokens.make_label(trend_word,12,Tokens.GREEN_TEXT if trend_word=="rising" else Tokens.RED_TEXT))
		var pct_label:=Tokens.make_label("%d%%" % roundi(pct),13,Tokens.text_for(color))
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


## One capacity with its recent years: its name, a small line of the last
## years, the change since last year, its level and bar. The whole row opens
## its history ("on_press").
static func _capacity_row(item:Dictionary)->Control:
	var pct:=clampf(float(item.get("pct",0.0)),0.0,100.0)
	var color:=Tokens.capacity_color(pct)
	var row:=PanelContainer.new()
	row.name="CapacityRow_"+String(item.get("id",item.get("name","")))
	row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var rest:=Tokens.flat(Color(0,0,0,0),Color(0,0,0,0),0,Tokens.RADIUS_CONTROL)
	rest.content_margin_left=6;rest.content_margin_right=6;rest.content_margin_top=3;rest.content_margin_bottom=4
	var hover:=rest.duplicate() as StyleBoxFlat
	hover.bg_color=Tokens.HOVER_BG
	row.add_theme_stylebox_override("panel",rest)
	row.tooltip_text=String(item.get("tip",""))
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",2)
	row.add_child(column)
	var top:=HBoxContainer.new()
	top.add_theme_constant_override("separation",8)
	column.add_child(top)
	var name_label:=Tokens.make_label(String(item.get("name","")),12,Tokens.BODY_2)
	name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var history:Array=Array(item.get("history",[]))
	if history.size()>=2:
		var line=preload("res://scripts/hud/hover_card.gd").Spark.new()
		line.name="Sparkline"
		line.values=history
		line.color=color
		line.custom_minimum_size=Vector2(96,18)
		line.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		top.add_child(line)
	if item.has("change_text"):
		var change_label:=Tokens.make_label(String(item.change_text),12,item.get("change_color",Tokens.MUTED))
		change_label.name="Change"
		change_label.custom_minimum_size=Vector2(52,0)
		change_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		top.add_child(change_label)
	var pct_label:=Tokens.make_label("%d%%" % roundi(pct),13,Tokens.text_for(color))
	pct_label.custom_minimum_size=Vector2(38,0)
	pct_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(pct_label)
	var track:=ColorRect.new()
	track.color=Tokens.TRACK
	track.custom_minimum_size=Vector2(0,5)
	column.add_child(track)
	var fill:=ColorRect.new()
	fill.color=color
	fill.anchor_right=pct/100.0
	fill.anchor_bottom=1.0
	fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	var action:Variant=item.get("on_press")
	if action is Callable:
		# The whole row is one hit target, lit under the pointer.
		for child:Node in row.find_children("*","Control",true,false):
			(child as Control).mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.mouse_filter=Control.MOUSE_FILTER_STOP
		row.focus_mode=Control.FOCUS_ALL
		row.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		row.mouse_entered.connect(func()->void:row.add_theme_stylebox_override("panel",hover))
		row.mouse_exited.connect(func()->void:row.add_theme_stylebox_override("panel",rest))
		row.gui_input.connect(func(event:InputEvent)->void:
			var mouse:=event as InputEventMouseButton
			if mouse and mouse.pressed and mouse.button_index==MOUSE_BUTTON_LEFT:
				row.accept_event();(action as Callable).call()
			elif event.is_action_pressed("ui_accept"):
				row.accept_event();(action as Callable).call())
	return row


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
		Live.attach(button,"disabled",item.get("live_disabled"))
		Live.attach(button,"tooltip_text",item.get("live_tip"))
		var column:=VBoxContainer.new()
		column.set_anchors_preset(Control.PRESET_FULL_RECT)
		column.offset_left=8;column.offset_right=-8
		column.alignment=BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation",1)
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(column)
		column.minimum_size_changed.connect(func():button.custom_minimum_size.y=maxf(38,column.get_combined_minimum_size().y+8))
		if item.get("texture") is Texture2D:
			var plate:=TextureRect.new();plate.texture=item.texture;plate.custom_minimum_size.y=160
			plate.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;plate.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(plate)
		var fg:=Tokens.DISABLED if disabled else (Tokens.GOLD_TEXT if primary else Tokens.BODY)
		var label:=Tokens.make_label(Tokens.sentence_case(String(item.get("label",""))),13,fg)
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
		Live.attach(label,"text",item.get("live_label"))
		if item.has("live_disabled"):
			Live.attach(label,"theme_override_colors/font_color",func()->Color: return Tokens.DISABLED if button.disabled else (Tokens.GOLD_TEXT if primary else Tokens.BODY))
		if String(item.get("sub",""))!="":
			var sub_label:=Tokens.make_label(String(item.sub),12,Tokens.MUTED)
			sub_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			sub_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
			column.add_child(sub_label)
			Live.attach(sub_label,"text",item.get("live_sub"))
		var action:Variant=item.get("on_press")
		if action is Callable:
			button.pressed.connect(func()->void:
				if button.disabled: return
				(action as Callable).call()
				_request_rebuild(button))


static func _render_image(parent:VBoxContainer,block:Dictionary)->void:
	## An illustration plate (expedition covers, portraits). Falls back to
	## quiet text while the referenced image has not been produced yet.
	var path:=String(block.get("path",""))
	var supplied:Texture2D=block.get("texture") as Texture2D
	if supplied==null and (path=="" or not ResourceLoader.exists(path)):
		if String(block.get("fallback",""))!="":
			var fallback:=Tokens.make_label(String(block.fallback),12,Tokens.MUTED)
			fallback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(fallback)
		return
	var frame:=TextureRect.new()
	frame.texture=supplied if supplied else load(path)
	frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED if bool(block.get("cover",false)) else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.custom_minimum_size=Vector2(0,float(block.get("height",216)))
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frame.tooltip_text=String(block.get("tip",""))
	parent.add_child(frame)


static func _render_text(parent:VBoxContainer,block:Dictionary)->void:
	var body:=Tokens.make_label(String(block.get("text","")),12,Tokens.TEXT_SOFT)
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(body)
	Live.attach(body,"text",block.get("live_text"))
