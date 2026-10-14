extends PanelContainer
## The reusable Dock: header (eyebrow/title/Close), provider sub-tabs, a
## four-tile KPI row, a decision brief with one direct action, and a scrolling
## body of DockBlocks. One instance serves all six sections; a second instance
## serves deep-detail views at x:652.

const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
const Blocks:=preload("res://scripts/hud/dock_blocks.gd")
const ViewState:=preload("res://scripts/hud/view_state.gd")
const Folio:=preload("res://scripts/hud/reference_folio.gd")
## Block types drawn purely from their dictionary. An identical block keeps its
## nodes across a live refresh; widget blocks may read live state, so they are
## always rebuilt (with their scroll and view state carried over).
const PURE_BLOCKS:=["discovery","line_chart","segments","alloc","bars","tiles","rows","caps","actions","conversation","order","image","text",""]

signal close_requested
signal tab_changed(sub:int)

var provider:Object
var sub:int=0
## The pages that share this screen (the rail's category), set by the HUD:
## [{section, provider, labels}]. With more than one, every page's tabs stand
## in the one row, so a category is one screen and nothing opens behind it.
var siblings:Array=[]
## Opens another page of the category: (section, sub).
var open_page:Callable=Callable()
var _flat:Array=[]
## The rail's word for this screen ("Economy"), set by the HUD: every page of
## a category carries it as its one title, with its tabs right under it. ""
## for a page outside the categories (a report), which keeps its own title.
var category_title:String=""
## A few quiet words beside the title (the town's name on Home).
var title_note:String=""
var note_label:Label
const TITLE_SIZE:=32
const TITLE_SIZE_NARROW:=26

var eyebrow_label:Label
var title_label:Label
var tab_buttons:Array[Button]=[]
var tabs_row:HFlowContainer
var kpi_row:GridContainer
var brief_panel:PanelContainer
var body_scroll:ScrollContainer
var body:VBoxContainer
var close_button:Button
var back_mode:bool=false
## Fingerprints of the rendered body sections, KPI row and brief, so a live
## refresh only replaces what changed.
var _section_prints:Array[String]=[]
## Each section's frame (type, heading, note): a widget takes new data in
## place only under the same frame, so its heading is never left stale.
var _section_frames:Array[String]=[]
var _kpi_print:=""
var _brief_print:=""
## Sections created since the dock was made (tests read this to prove reuse).
var sections_built:=0

func _ready()->void:
	name="DockPanel" if name=="" or String(name).begins_with("@") else name
	var panel_style:=Folio.page_style()
	add_theme_stylebox_override("panel",panel_style)
	clip_contents=true
	add_child(Folio.paper())
	var root:=VBoxContainer.new();root.name="DockContentRoot"
	root.add_theme_constant_override("separation",0)
	add_child(root)
	# Header
	var header:=MarginContainer.new()
	header.add_theme_constant_override("margin_left",26)
	header.add_theme_constant_override("margin_right",26)
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
	eyebrow_label=Tokens.make_label("",12,Tokens.GOLD_TEXT,0.06)
	title_column.add_child(eyebrow_label)
	title_label=Tokens.make_label("",21,Tokens.INK)
	title_column.add_child(title_label)
	title_column.move_child(title_label,0)
	title_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	eyebrow_label.add_theme_font_override("font",Tokens.font("voice_italic"))
	eyebrow_label.add_theme_font_size_override("font_size",15)
	eyebrow_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var close:=Button.new()
	close_button=close
	close.name="DockClose"
	# One clear control: "Back" in the detail dock, "Close" in the main dock.
	# Esc does the same; the tooltip says so, so no separate ESC label.
	close.text="‹" if back_mode else "×"
	close.custom_minimum_size=Vector2(32,34)
	close.tooltip_text="Back to the previous page (Esc)" if back_mode else "Close and return to the map (Esc)"
	close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	close.add_theme_font_size_override("font_size",28)
	close.add_theme_font_override("font",Tokens.font("voice"))
	close.add_theme_color_override("font_color",Tokens.TEXT_DIM)
	close.add_theme_stylebox_override("normal",Tokens.flat(Color.TRANSPARENT))
	close.add_theme_stylebox_override("hover",Tokens.flat(Tokens.CLOSE_HOVER_BG,Tokens.BORDER_2,1,4))
	close.add_theme_stylebox_override("focus",Tokens.gold_outline_style())
	close.pressed.connect(func()->void: close_requested.emit())
	note_label=Tokens.make_label("",16,Tokens.GOLD_TEXT);note_label.name="TitleNote"
	note_label.add_theme_font_override("font",Tokens.font("voice_italic"));note_label.add_theme_font_size_override("font_size",17)
	note_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;note_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	note_label.visible=false
	header_row.add_child(note_label)
	header_row.add_child(close)
	# Sub-tabs
	var tabs_margin:=MarginContainer.new()
	tabs_margin.add_theme_constant_override("margin_left",26)
	tabs_margin.add_theme_constant_override("margin_right",26)
	root.add_child(tabs_margin)
	tabs_row=HFlowContainer.new()
	tabs_row.add_theme_constant_override("h_separation",4)
	tabs_row.add_theme_constant_override("v_separation",4)
	tabs_margin.add_child(tabs_row)
	var tabs_rule:=ColorRect.new();tabs_rule.name="TabRule"
	tabs_rule.color=Tokens.BORDER
	tabs_rule.custom_minimum_size=Vector2(0,1)
	root.add_child(tabs_rule)
	# KPI row
	var kpi_margin:=MarginContainer.new();kpi_margin.name="KpiMargin"
	kpi_margin.add_theme_constant_override("margin_left",26)
	kpi_margin.add_theme_constant_override("margin_right",26)
	kpi_margin.add_theme_constant_override("margin_top",18)
	root.add_child(kpi_margin)
	kpi_row=GridContainer.new()
	kpi_row.columns=4
	kpi_row.add_theme_constant_override("h_separation",8)
	kpi_margin.add_child(kpi_row)
	# Decision brief
	var brief_margin:=MarginContainer.new();brief_margin.name="BriefMargin"
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
	body_margin.add_theme_constant_override("margin_left",26)
	body_margin.add_theme_constant_override("margin_right",26)
	body_margin.add_theme_constant_override("margin_top",24)
	body_margin.add_theme_constant_override("margin_bottom",26)
	body_scroll.add_child(body_margin)
	body=VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",24)
	body_margin.add_child(body)
	resized.connect(_on_resized)
	body.minimum_size_changed.connect(func()->void:
		if fit_height:call_deferred("_fit"))


func present(new_provider:Object,new_sub:int=0)->void:
	if provider!=new_provider or sub!=new_sub:
		body_scroll.scroll_vertical=0
		_clear_body()
	provider=new_provider
	sub=maxi(0,new_sub)
	rebuild()


func rebuild()->void:
	if provider==null: return
	var meta:Dictionary=provider.meta()
	_set_fit(bool(meta.get("fit_height",false)))
	# Providers still pass shouted text; the dock speaks in sentence case.
	# One header on every screen: the rail's word on one line, the tabs right
	# under it. A report outside the categories keeps its own title and line.
	eyebrow_label.text="" if category_title!="" else Tokens.sentence_case(String(meta.get("eyebrow","")))
	eyebrow_label.visible=eyebrow_label.text!=""
	title_label.text=category_title if category_title!="" else Tokens.sentence_case(String(meta.get("title","")))
	title_label.add_theme_font_size_override("font_size",TITLE_SIZE if size.x>=600 else TITLE_SIZE_NARROW)
	title_label.add_theme_font_override("font",Tokens.font("ui_strong"))
	note_label.text=title_note if category_title!="" else ""
	note_label.visible=note_label.text!=""
	var own:Array=meta.get("subtabs",[])
	sub=clampi(sub,0,maxi(0,own.size()-1))
	_flat=_flat_tabs(own)
	var subtabs:Array=_flat.map(func(entry:Dictionary)->String:return String(entry.text))
	tabs_row.visible=subtabs.size()>1
	while tab_buttons.size()<subtabs.size():
		var tab:=Button.new()
		tab.custom_minimum_size=Vector2(0,38)
		tab.add_theme_font_override("font",Tokens.font("ui"))
		tab.add_theme_font_size_override("font_size",12)
		tab.add_theme_stylebox_override("focus",Tokens.gold_outline_style())
		tab.pressed.connect(_on_tab_pressed.bind(tab_buttons.size()))
		tabs_row.add_child(tab)
		tab_buttons.append(tab)
	for index in tab_buttons.size():
		var tab:=tab_buttons[index]
		tab.visible=index<subtabs.size()
		if index<subtabs.size(): tab.text=Tokens.sentence_case(String(subtabs[index]))
		var active:=index<_flat.size() and bool(_flat[index].active)
		tab.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		var style:=Tokens.flat(Tokens.GOLD_WASH if active else Color.TRANSPARENT)
		style.border_color=Tokens.GOLD
		style.border_width_bottom=2 if active else 0
		# Tabs wrap at a readable size instead of squeezing a long category.
		var many:=subtabs.size()>5
		style.content_margin_left=10;style.content_margin_right=10
		tab.add_theme_font_size_override("font_size",15 if many else 16)
		tab.add_theme_stylebox_override("normal",style)
		var hover:=style.duplicate() as StyleBoxFlat;hover.bg_color=Tokens.HOVER_BG
		tab.add_theme_stylebox_override("hover",hover)
		tab.add_theme_stylebox_override("pressed",style)
		tab.add_theme_color_override("font_color",Tokens.INK if active else Tokens.TEXT_DIM)
		tab.add_theme_color_override("font_hover_color",Tokens.INK)
	rebuild_body()


func rebuild_body()->void:
	if provider==null: return
	var data:Dictionary=provider.tab(sub)
	if category_title=="" and not data.get("blocks",[]).is_empty() and data.blocks[0].get("type","") in ["materials_ledger","wealth_ledger"]:title_label.text=String(data.blocks[0].title)
	# Keep what the player is looking at: scroll offsets (the dock's and any
	# nested one), the focused control, and widget page state.
	var view:=ViewState.capture(body_scroll)
	var kpi_print:=fingerprint(data.get("kpis",[]))
	if kpi_print!=_kpi_print:
		_kpi_print=kpi_print
		_rebuild_kpis(data.get("kpis",[]))
	var brief_print:=fingerprint(data.get("brief",{}))
	if brief_print!=_brief_print:
		_brief_print=brief_print
		_rebuild_brief(data.get("brief",{}))
	_render_sections(data.get("blocks",[]))
	# Every dock, the recruiting board included, is paper and ink. Set again
	# only when the palette moved: setting a style or ink, even the same one,
	# lays the whole dock out again on the next frame.
	var military_board:bool=not data.get("blocks",[]).is_empty() and data.blocks[0].get("type","")=="recruit_deploy"
	var paper:=Folio.page_style()
	var surface:=get_node_or_null("FolioPaper") as ColorRect
	if surface and surface.material is ShaderMaterial:
		(surface.material as ShaderMaterial).set_shader_parameter("paper_color",Tokens.PAPER)
	var laid:=get_theme_stylebox("panel") as StyleBoxFlat
	if laid==null or laid.bg_color!=paper.bg_color or laid.border_color!=paper.border_color or laid.border_width_top!=paper.border_width_top or laid.corner_radius_top_left!=paper.corner_radius_top_left or not has_theme_stylebox_override("panel"):
		add_theme_stylebox_override("panel",paper)
	if military_board and category_title=="":title_label.text="Recruit and deploy"
	_ink(title_label,"font_color",Tokens.INK)
	_ink(eyebrow_label,"font_color",Tokens.GOLD_TEXT)
	_ink(close_button,"font_color",Tokens.TEXT_DIM)
	ViewState.restore(body_scroll,view)


static func _ink(control:Control,item:StringName,color:Color)->void:
	if not control.has_theme_color_override(item) or control.get_theme_color(item)!=color:control.add_theme_color_override(item,color)


func _render_sections(blocks:Array)->void:
	## One body section per block. An unchanged pure block keeps its nodes; a
	## changed one is replaced in place, at the same index.
	var old:Array[Node]=body.get_children()
	var prints:Array[String]=[]
	var frames:Array[String]=[]
	for index in blocks.size():
		var block:Dictionary=blocks[index]
		var block_print:=section_print(block)
		var frame:=section_frame(block)
		prints.append(block_print)
		frames.append(frame)
		var known:=index<old.size() and index<_section_prints.size() and index<_section_frames.size()
		if known and _section_prints[index]==block_print and reusable(block):
			continue
		# A widget that can take new data in place keeps its nodes (the People
		# screen's scene, open card and figures) instead of being replaced.
		if known and _section_frames[index]==frame:
			var widget:=_in_place_widget(old[index])
			if widget!=null and bool(widget.call("update_block",block)):continue
		var before:=body.get_child_count()
		Blocks.render(body,[block])
		sections_built+=body.get_child_count()-before
		var fresh:=body.get_child(body.get_child_count()-1)
		if index<old.size():
			var stale:=old[index]
			body.move_child(fresh,stale.get_index())
			body.remove_child(stale);stale.queue_free()
		else:body.move_child(fresh,index)
	for index in range(blocks.size(),old.size()):
		if is_instance_valid(old[index]) and old[index].get_parent()==body:
			body.remove_child(old[index]);old[index].queue_free()
	_section_prints=prints
	_section_frames=frames


## What a body section is compared by between refreshes. A pure block: its
## whole dictionary. A block whose provider gives a `_print` (the exact inputs
## it was made from; the same print always means the same content): that
## print, so it keeps its nodes like a pure block. Any other widget: only its
## frame, since it is rebuilt or updated in place whatever its data (walking
## a large widget's data here cost more than drawing it).
static func section_print(block:Dictionary)->String:
	var type:=String(block.get("type",""))
	if block.has("_print"):return section_frame(block)+"|#"+str(block._print)
	if type in PURE_BLOCKS:return type+"|"+fingerprint(block)
	return section_frame(block)

## A section's type and the heading and note drawn above it.
static func section_frame(block:Dictionary)->String:
	return "%s|%s|%s" % [String(block.get("type","")),str(block.get("heading","")),str(block.get("note",""))]

## A section whose print is unchanged keeps its nodes.
static func reusable(block:Dictionary)->bool:
	return block.has("_print") or String(block.get("type","")) in PURE_BLOCKS


static func _in_place_widget(section:Node)->Node:
	if section==null or not is_instance_valid(section):return null
	for child in section.get_children():
		if child.has_method("update_block"):return child
	return null


static func fingerprint(value:Variant)->String:
	## Stable text for a block/KPI dictionary. Callables and objects are named,
	## not hashed, because each rebuild makes fresh lambdas.
	match typeof(value):
		TYPE_DICTIONARY:
			var parts:PackedStringArray=[]
			var keys:Array=(value as Dictionary).keys();keys.sort()
			for key in keys:parts.append(str(key)+":"+fingerprint(value[key]))
			return "{"+",".join(parts)+"}"
		TYPE_ARRAY:
			var parts:PackedStringArray=[]
			for item in value:parts.append(fingerprint(item))
			return "["+",".join(parts)+"]"
		TYPE_CALLABLE:
			var callable:Callable=value
			return "fn:"+String(callable.get_method())+str(callable.get_bound_arguments())
		TYPE_OBJECT:
			return "obj:"+(str((value as Object).get_instance_id()) if is_instance_valid(value) else "null")
		_:
			return var_to_str(value)


func _clear_body()->void:
	## A different view: nothing of the previous one is kept.
	_section_prints.clear()
	_section_frames.clear()
	for child in body.get_children():
		body.remove_child(child);child.queue_free()


## One row on a wide page for up to six tiles; four across beyond that.
func _kpi_columns()->void:
	if kpi_row==null:return
	var count:=kpi_row.get_child_count()
	kpi_row.columns=2 if size.x<600 else (count if count>=1 and count<=6 else 4)


## The tiles under the tabs: {label, value, delta, tip, and optionally
## meter (0..1, a bar under the number), meter_color, glance (true: a big
## number and its bar, the note in the pointer), on_press (opens its page)}.
func _rebuild_kpis(kpis:Array)->void:
	kpi_row.get_parent().visible=not kpis.is_empty()
	for child in kpi_row.get_children():
		kpi_row.remove_child(child)
		child.queue_free()
	for kpi_variant in kpis:
		var kpi:Dictionary=kpi_variant
		var glance:=bool(kpi.get("glance",false))
		var tile:=PanelContainer.new()
		tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",Tokens.flat(Color.TRANSPARENT))
		tile.tooltip_text=String(kpi.get("tip",""))
		kpi_row.add_child(tile)
		var press:Variant=kpi.get("on_press")
		if press is Callable and (press as Callable).is_valid():
			tile.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
			tile.gui_input.connect(func(event:InputEvent)->void:
				if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
					tile.accept_event();(press as Callable).call())
		var column:=VBoxContainer.new()
		column.add_theme_constant_override("separation",4)
		column.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(column)
		var caption:=Tokens.make_label(String(kpi.get("label","")),12,Tokens.MUTED,0.06)
		caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(caption)
		var value_row:=VBoxContainer.new()
		value_row.add_theme_constant_override("separation",6)
		column.add_child(value_row)
		var value_label:=Tokens.make_label(String(kpi.get("value","")),28,Tokens.INK)
		value_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		value_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		value_label.add_theme_font_override("font",Tokens.font("ui_strong"))
		if glance:
			value_label.add_theme_font_override("font",Tokens.font("ui_strong"));value_label.add_theme_font_size_override("font_size",28)
		value_row.add_child(value_label)
		preload("res://scripts/hud/live_value_binding.gd").attach(value_label,"text",kpi.get("live_value"))
		if String(kpi.get("delta",""))!="" and not glance:
			var delta:=Tokens.make_label(String(kpi.delta),14,Tokens.text_for(kpi.get("delta_color",Tokens.MUTED)))
			delta.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			delta.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM
			value_row.add_child(delta)
			preload("res://scripts/hud/live_value_binding.gd").attach(delta,"text",kpi.get("live_delta"))
		if kpi.has("meter"):
			var meter:=ProgressBar.new();meter.name="KpiMeter";meter.show_percentage=false;meter.min_value=0.0;meter.max_value=1.0
			meter.value=clampf(float(kpi.meter),0.0,1.0);meter.custom_minimum_size=Vector2(0,6);meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var track:=Tokens.flat(Color(Tokens.INK,0.12),Color(0,0,0,0),0,2)
			var fill:=Tokens.flat(kpi.get("meter_color",Tokens.GREEN),Color(0,0,0,0),0,2)
			meter.add_theme_stylebox_override("background",track);meter.add_theme_stylebox_override("fill",fill)
			column.add_child(meter)
		# Or one bar split by share ({share, color, label, value}).
		elif kpi.has("segments"):
			var split:Control=preload("res://scripts/hud/buildings_board.gd").Segments.new();split.name="KpiSegments"
			split.set("items",kpi.segments);split.custom_minimum_size=Vector2(0,6);split.mouse_filter=Control.MOUSE_FILTER_IGNORE
			column.add_child(split)
		# A glance tile says its few words under the bar.
		if glance and String(kpi.get("delta",""))!="":
			var words:=Tokens.make_label(String(kpi.delta),14,Tokens.text_for(kpi.get("delta_color",Tokens.MUTED)))
			words.name="KpiWords";words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.mouse_filter=Control.MOUSE_FILTER_IGNORE
			column.add_child(words)
		# What the number means is written on the tile, not hidden in a tooltip.
		var tip:=String(kpi.get("tip",""))
		if tip!="" and not glance:
			var note:=Tokens.make_label(tip,14,Tokens.TEXT_DIM)
			note.name="KpiNote"
			note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			note.custom_minimum_size.x=0
			note.max_lines_visible=-1
			column.add_child(note)
	_kpi_columns()


func _rebuild_brief(brief:Dictionary)->void:
	brief_panel.get_parent().visible=not brief.is_empty()
	for child in brief_panel.get_children():
		brief_panel.remove_child(child)
		child.queue_free()
	brief_panel.visible=not brief.is_empty()
	if brief.is_empty(): return
	brief_panel.add_theme_stylebox_override("panel",Tokens.brief_style(String(brief.get("tone","info"))))
	if bool(brief.get("folio",false)):
		var style:=Tokens.flat(Color.TRANSPARENT)
		style.border_width_bottom=1;style.border_color=Folio.RULE
		style.content_margin_left=8;style.content_margin_right=8
		style.content_margin_bottom=14
		brief_panel.add_theme_stylebox_override("panel",style)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	brief_panel.add_child(row)
	var text_column:=VBoxContainer.new()
	text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation",2)
	row.add_child(text_column)
	var brief_title:=Tokens.make_label(Tokens.sentence_case(String(brief.get("title",""))),20,Tokens.INK)
	brief_title.add_theme_font_override("font",Tokens.font("ui_strong"))
	brief_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(brief_title)
	var why:=Tokens.make_label(String(brief.get("why","")),14,Tokens.TEXT_SOFT)
	why.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(why)
	if String(brief.get("action_label",""))!="":
		var action:=Button.new()
		action.name="BriefAction"
		action.text=Tokens.sentence_case(String(brief.action_label))
		action.custom_minimum_size=Vector2(0,34)
		action.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		action.add_theme_font_size_override("font_size",14)
		action.add_theme_color_override("font_color",Tokens.GOLD_TEXT)
		action.add_theme_stylebox_override("normal",Tokens.gold_outline_style())
		action.add_theme_stylebox_override("hover",Tokens.gold_outline_style())
		action.add_theme_stylebox_override("focus",Tokens.gold_outline_style())
		var on_action:Variant=brief.get("on_action")
		if on_action is Callable:
			action.pressed.connect(on_action)
		row.add_child(action)


## Every tab of the screen in one row: this page's own, and its category
## neighbours' (a page with one tab stands as one tab under its own name).
func _flat_tabs(own:Array)->Array:
	var out:Array=[]
	var shared:=siblings.size()>1 and siblings.any(func(page:Dictionary)->bool:return page.provider==provider)
	if not shared:
		var meta:Dictionary=provider.meta()
		var aliases:Dictionary=meta.get("subtab_aliases",{})
		for index in own.size():
			if index in meta.get("hidden_subtabs",[]):continue
			out.append({"text":String(own[index]),"mine":true,"sub":index,"active":index==int(aliases.get(sub,sub))})
		return out
	for page:Dictionary in siblings:
		var mine:bool=page.provider==provider
		var meta:Dictionary=(page.provider as Object).meta()
		var aliases:Dictionary=meta.get("subtab_aliases",{})
		var names:Array=own if mine else (meta.get("subtabs",[]) as Array)
		var labels:Array=page.get("labels",[])
		for index in maxi(1,names.size()):
			if index in meta.get("hidden_subtabs",[]):continue
			var text:=String(labels[index]) if index<labels.size() else (String(names[index]) if index<names.size() else String(page.section).capitalize())
			out.append({"text":text,"mine":mine,"section":String(page.section),"sub":index,"active":mine and index==int(aliases.get(sub,sub))})
	return out

func _on_tab_pressed(index:int)->void:
	if index>=_flat.size():return
	var entry:Dictionary=_flat[index]
	if not bool(entry.mine):
		if open_page.is_valid():open_page.call(String(entry.section),int(entry.sub))
		return
	index=int(entry.sub)
	if index==sub: return
	body_scroll.scroll_vertical=0
	_clear_body()
	sub=index
	rebuild()
	tab_changed.emit(sub)
	# Tab change: the new content cross-fades in (Motion.BASE, cubic ease-out).
	preload("res://scripts/hud/motion.gd").cross_fade(body_scroll)


# --- Fitting a short screen ------------------------------------------------------
## A provider whose meta() says "fit_height" gets a dock that ends where its
## content ends (up to the room the HUD gives it) instead of a tall empty
## sheet under a short screen. Other docks keep the full height.
var fit_height:=false
var _room:=0.0
var _fitting:=false

func _set_fit(enabled:bool)->void:
	if enabled==fit_height:return
	fit_height=enabled
	if enabled:call_deferred("_fit")
	elif _room>0.0 and size.y<_room-1.0:
		_fitting=true;size.y=_room;_fitting=false

func _on_resized()->void:
	if title_label:
		title_label.add_theme_font_size_override("font_size",TITLE_SIZE if size.x>=600 else TITLE_SIZE_NARROW)
		for tab:Button in tab_buttons:tab.add_theme_font_size_override("font_size",15 if _flat.size()>5 else 16)
	_kpi_columns()
	if _fitting:return
	_room=size.y
	if fit_height:call_deferred("_fit")

func _fit()->void:
	if not fit_height or _room<=0.0 or get_child_count()==0:return
	var chrome:=(get_node("DockContentRoot") as Control).get_combined_minimum_size().y
	var style:=get_theme_stylebox("panel")
	if style!=null:chrome+=style.get_minimum_size().y
	# The body's own margins (12 above, 18 below) are outside its minimum size.
	var wanted:=minf(_room,ceilf(chrome+body.get_combined_minimum_size().y+30.0))
	if absf(size.y-wanted)>1.0:
		_fitting=true;size.y=wanted;_fitting=false
