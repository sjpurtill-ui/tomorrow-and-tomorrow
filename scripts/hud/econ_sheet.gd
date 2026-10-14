extends RefCounted
## The Economy pages' shared parts, so every tab reads the same way:
##   a KPI strip (3 to 6 figures across the top, each with a bar against a
##   stated maximum), one-line rows (icon, label, value, small bar, coloured
##   tag, small verb buttons on the row), small gold section heads, and grids
##   that flow rows into two or three columns on a wide page.
## Every builder returns the nodes a live refresh writes into, so a page can
## keep its nodes (and an open tooltip) while the day's numbers change.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

const ROW_HEIGHT:=24.0
const ICON_SIZE:=20.0

## A whole number with its thousands separators (era_words.gd grouped, the
## one formatter every page uses).
static func n(value:float)->String:
	if absf(value)<10.0 and not is_equal_approx(value,roundf(value)):
		var text:="%.1f" % value
		return text.trim_suffix(".0")
	return EraWords.grouped(roundi(value))

## "+1,234" / "−1,234" / "0".
static func signed(value:float)->String:
	if absf(value)<0.5:return "0"
	return ("+" if value>0.0 else "−")+n(absf(value))

static func label(text:String,size:int,color:Color,strong:=false)->Label:
	var l:=Label.new();l.text=text;l.mouse_filter=Control.MOUSE_FILTER_PASS
	l.add_theme_font_override("font",T.font("ui_strong" if strong else "ui"))
	l.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size))
	l.add_theme_color_override("font_color",color)
	return l

static func voice(text:String,size:int,color:Color=T.INK)->Label:
	var l:=label(text,size,color);l.add_theme_font_override("font",T.voice_font())
	return l

## Words written only when they differ (keeps an unchanged line's layout).
static func put(l:Label,text:String,color:Variant=null)->void:
	if l==null:return
	if l.text!=text:l.text=text
	if color is Color and l.get_theme_color("font_color")!=color:l.add_theme_color_override("font_color",color)

static func icon(key:String,size:float=ICON_SIZE,kind:String="resource")->TextureRect:
	var rect:=TextureRect.new();rect.custom_minimum_size=Vector2(size,size)
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_vertical=Control.SIZE_SHRINK_CENTER;rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if not key.is_empty():
		match kind:
			"people":rect.texture=Icons.people_texture(key,T.INK_MUTED,48,false)
			"workshop":rect.texture=Icons.workshop_texture(key,T.INK_MUTED,48)
			"chart":rect.texture=Icons.chart_texture(key,T.INK_MUTED,40)
			_:rect.texture=Icons.material_texture(key,48)
	return rect

## A thin bar: value against a stated maximum.
static func bar(ratio:float,color:Color,width:float=0.0,height:float=6.0)->Bar:
	var b:=Bar.new();b.ratio=ratio;b.color=color;b.custom_minimum_size=Vector2(width,height)
	b.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	if width<=0.0:b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return b

## A small coloured state tag ("Empty", "Stalled", "Full").
static func tag(text:String,color:Color)->Label:
	var l:=label(text,12,T.legible(color,T.DOCK_BG),true)
	var style:=T.flat(Color(color,0.14),Color(color,0.55),1,3,0)
	style.content_margin_left=6;style.content_margin_right=6;style.content_margin_top=1;style.content_margin_bottom=1
	l.add_theme_stylebox_override("normal",style)
	l.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return l

static func set_tag(l:Label,text:String,color:Color)->void:
	if l==null:return
	l.visible=not text.is_empty()
	put(l,text,T.legible(color,T.DOCK_BG))
	var style:=l.get_theme_stylebox("normal") as StyleBoxFlat
	if style!=null and style.bg_color!=Color(color,0.14):
		style=style.duplicate();style.bg_color=Color(color,0.14);style.border_color=Color(color,0.55);l.add_theme_stylebox_override("normal",style)

## A small verb button ("Build", "Ask", "Show"): on the row or beside the
## figure it changes. `chosen` marks the current one of a set of choices.
static func verb(text:String,callback:Variant,tip:String="",chosen:=false,primary:=false)->Button:
	var b:=Button.new();b.text=text;b.tooltip_text=tip;b.focus_mode=Control.FOCUS_NONE
	b.custom_minimum_size=Vector2(0,24);b.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font",T.font("ui_strong" if chosen or primary else "ui"))
	b.add_theme_font_size_override("font_size",13)
	b.add_theme_color_override("font_color",T.INK if chosen else T.BODY);b.add_theme_color_override("font_hover_color",T.INK)
	b.add_theme_color_override("font_disabled_color",T.DISABLED)
	var normal:=T.flat(T.ACTIVE_BG if chosen else (T.BUTTON_BG if primary else Color.TRANSPARENT),T.GOLD if chosen or primary else T.BORDER_SOFT,1,2,0)
	normal.content_margin_left=8;normal.content_margin_right=8;normal.content_margin_top=2;normal.content_margin_bottom=2
	if chosen:normal.border_width_bottom=2
	var hover:=normal.duplicate() as StyleBoxFlat;hover.bg_color=T.HOVER_BG;hover.border_color=T.GOLD
	var disabled:=normal.duplicate() as StyleBoxFlat;disabled.border_color=T.TRACK;disabled.bg_color=Color.TRANSPARENT
	b.add_theme_stylebox_override("normal",normal);b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("pressed",normal);b.add_theme_stylebox_override("disabled",disabled)
	if callback is Callable and (callback as Callable).is_valid():b.pressed.connect(callback)
	else:b.disabled=true
	return b

## A small gold section head with a hairline under it; `right` is a short
## figure or note at the head's far end.
static func head(parent:Node,text:String,right:String="",tip:String="")->Dictionary:
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",3);parent.add_child(box)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);box.add_child(row)
	var title:=label(text.to_upper(),12,T.GOLD_TEXT,true);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.tooltip_text=tip;row.add_child(title)
	var side:=label(right,12,T.INK_MUTED);row.add_child(side)
	var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size=Vector2(0,1);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(rule)
	return {"box":box,"row":row,"title":title,"side":side}

## A grid that holds rows in 1 to `most` columns by the width it is given
## (`min_column` px a column). Call flow() from the page's resized signal.
static func columns(parent:Node,node_name:String,min_column:float=380.0,most:int=2)->GridContainer:
	var grid:=GridContainer.new();grid.name=node_name;grid.columns=1;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",22);grid.add_theme_constant_override("v_separation",2)
	grid.set_meta("min_column",min_column);grid.set_meta("most",most)
	parent.add_child(grid)
	return grid

static func flow(grid:GridContainer,width:float)->void:
	if grid==null or not is_instance_valid(grid):return
	var columns:=clampi(floori((width+22.0)/(float(grid.get_meta("min_column",380.0))+22.0)),1,int(grid.get_meta("most",2)))
	if grid.columns!=columns:grid.columns=columns

# --------------------------------------------------------------------------
# The KPI strip
# --------------------------------------------------------------------------

## The strip across the top of a tab: one cell a figure. Each item is
## {id, label, value, sub, ratio (-1: no bar), color, tip, icon, icon_kind,
## value_color, action:{text, on_press, tip}}. Returns {id: cell refs}.
static func kpi_strip(parent:Node,items:Array,node_name:String="Kpis")->Dictionary:
	var strip:=GridContainer.new();strip.name=node_name;strip.columns=maxi(1,items.size());strip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("h_separation",10);strip.add_theme_constant_override("v_separation",8)
	parent.add_child(strip)
	var refs:={}
	for item:Dictionary in items:refs[String(item.get("id",item.get("label","")))]=kpi_cell(strip,item)
	return refs

static func kpi_cell(parent:Node,item:Dictionary)->Dictionary:
	var panel:=PanelContainer.new();panel.name="Kpi_"+String(item.get("id",item.get("label",""))).validate_node_name()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,0)
	style.content_margin_left=9;style.content_margin_right=9;style.content_margin_top=5;style.content_margin_bottom=5
	style.border_width_top=2;style.border_color=T.RULE
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",1);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(box)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",5);top.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(top)
	var key:=String(item.get("icon",""))
	if not key.is_empty():top.add_child(icon(key,16,String(item.get("icon_kind","resource"))))
	var caption:=label(String(item.get("label","")).to_upper(),11,T.INK_MUTED,true);caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL;caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER;caption.clip_text=true;caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;caption.custom_minimum_size.x=40;caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;top.add_child(caption)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",4);line.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(line)
	var value:=voice("",24);value.mouse_filter=Control.MOUSE_FILTER_IGNORE;value.size_flags_horizontal=Control.SIZE_EXPAND_FILL;value.clip_text=true;value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;value.custom_minimum_size.x=48;line.add_child(value)
	var action:Button=null
	if item.get("action") is Dictionary:
		var a:Dictionary=item.action
		action=verb(String(a.get("text","")),a.get("on_press"),String(a.get("tip","")),bool(a.get("chosen",false)));action.custom_minimum_size.y=20;action.add_theme_font_size_override("font_size",12);line.add_child(action)
	var meter:=bar(0.0,T.GOLD,0.0,5.0);meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(meter)
	var sub:=label("",12,T.INK_MUTED);sub.mouse_filter=Control.MOUSE_FILTER_IGNORE;sub.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;sub.custom_minimum_size.x=60;box.add_child(sub)
	var refs:={"panel":panel,"value":value,"bar":meter,"sub":sub,"caption":caption,"action":action,"style":style}
	set_kpi(refs,item)
	return refs

static func set_kpi(refs:Dictionary,item:Dictionary)->void:
	var color:Color=item.get("color",T.GOLD)
	put(refs.value,String(item.get("value","")),item.get("value_color",T.INK))
	put(refs.sub,String(item.get("sub","")),item.get("sub_color",T.INK_MUTED))
	(refs.sub as Control).visible=String(item.get("sub",""))!=""
	var ratio:=float(item.get("ratio",-1.0))
	var meter:Bar=refs.bar
	meter.visible=ratio>=0.0
	if ratio>=0.0 and (meter.ratio!=ratio or meter.color!=color):meter.ratio=ratio;meter.color=color;meter.queue_redraw()
	var tip:=String(item.get("tip",""))
	if (refs.panel as Control).tooltip_text!=tip:(refs.panel as Control).tooltip_text=tip
	var style:StyleBoxFlat=refs.style
	var edge:Color=item.get("edge",T.RULE)
	if style.border_color!=edge:
		style=style.duplicate();style.border_color=edge;(refs.panel as PanelContainer).add_theme_stylebox_override("panel",style);refs.style=style

# --------------------------------------------------------------------------
# One-line rows
# --------------------------------------------------------------------------

## One fact on one line: [icon] label ... [bar] value [tag] [buttons].
## item: {icon, icon_kind, label, value, value_color, ratio (-1 none),
## bar_color, bar_width, note (small grey text after the label), tag,
## tag_color, tip, buttons:[{text,on_press,tip,chosen,primary,disabled}]}.
static func row(parent:Node,item:Dictionary)->Dictionary:
	var panel:=PanelContainer.new();panel.name="Row_"+String(item.get("id",item.get("label",""))).validate_node_name()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=StyleBoxFlat.new();style.bg_color=Color.TRANSPARENT;style.border_width_bottom=1;style.border_color=Color(T.RULE,0.45)
	style.content_margin_top=1;style.content_margin_bottom=1;style.content_margin_left=2;style.content_margin_right=2
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);line.custom_minimum_size.y=ROW_HEIGHT;line.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(line)
	var key:=String(item.get("icon",""))
	var glyph:TextureRect=null
	if item.has("icon"):glyph=icon(key,ICON_SIZE,String(item.get("icon_kind","resource")));line.add_child(glyph)
	var name_label:=label(String(item.get("label","")),14,T.INK);name_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	name_label.clip_text=true;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	# The name takes its share of a wide row and gives way on a narrow one.
	name_label.custom_minimum_size.x=minf(70.0,float(item.get("label_width",150.0)))
	name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.size_flags_stretch_ratio=float(item.get("label_width",150.0))/150.0
	line.add_child(name_label)
	var note:=label("",12,T.INK_MUTED);note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;note.size_flags_stretch_ratio=1.6;note.custom_minimum_size.x=1;note.size_flags_vertical=Control.SIZE_SHRINK_CENTER;note.clip_text=true;note.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;note.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(note)
	var spark:Control=null
	if item.has("points"):
		spark=preload("res://scripts/hud/material_stock_spark.gd").new();spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;spark.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(spark)
		var spark_width:=float(item.get("bar_width",70.0))
		spark.ready.connect(func()->void:spark.custom_minimum_size=Vector2(spark_width,22);spark.mouse_filter=Control.MOUSE_FILTER_IGNORE;spark.tooltip_text="")
	var meter:=bar(0.0,T.GOLD,float(item.get("bar_width",70.0)),6.0);meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(meter)
	var value:=label("",15,T.INK,true);value.size_flags_vertical=Control.SIZE_SHRINK_CENTER;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;value.custom_minimum_size.x=float(item.get("value_width",72.0));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(value)
	var state:=tag("",T.MUTED);state.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(state)
	var buttons:Array=[]
	for spec:Dictionary in item.get("buttons",[]):
		var b:=verb(String(spec.get("text","")),spec.get("on_press"),String(spec.get("tip","")),bool(spec.get("chosen",false)),bool(spec.get("primary",false)))
		if bool(spec.get("disabled",false)):b.disabled=true
		line.add_child(b);buttons.append(b)
	var refs:={"panel":panel,"label":name_label,"note":note,"bar":meter,"value":value,"tag":state,"buttons":buttons,"icon":glyph,"spark":spark}
	set_row(refs,item)
	return refs

static func set_row(refs:Dictionary,item:Dictionary)->void:
	put(refs.label,String(item.get("label","")),item.get("label_color",T.INK))
	put(refs.note,String(item.get("note","")),item.get("note_color",T.INK_MUTED))
	put(refs.value,String(item.get("value","")),item.get("value_color",T.INK))
	var ratio:=float(item.get("ratio",-1.0))
	var meter:Bar=refs.bar
	meter.visible=ratio>=0.0
	var color:Color=item.get("bar_color",T.GOLD)
	if ratio>=0.0 and (meter.ratio!=ratio or meter.color!=color):meter.ratio=ratio;meter.color=color;meter.queue_redraw()
	set_tag(refs.tag,String(item.get("tag","")),item.get("tag_color",T.MUTED))
	var spark:Control=refs.get("spark")
	if spark!=null and item.has("points") and spark.get("points")!=item.points:spark.set("points",item.points);spark.queue_redraw()
	var tip:=String(item.get("tip",""))
	if (refs.panel as Control).tooltip_text!=tip:(refs.panel as Control).tooltip_text=tip

## A row's shape for a live refresh: which buttons it has.
static func row_shape(item:Dictionary)->Array:
	var out:Array=[String(item.get("id",item.get("label",""))),item.has("icon")]
	for spec:Dictionary in item.get("buttons",[]):out.append([String(spec.get("text","")),bool(spec.get("chosen",false)),bool(spec.get("disabled",false))])
	return out

## A bar drawn plainly: the track, the fill, and a hairline at a mark.
class Bar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var ratio:=0.0
	var color:=Color("8a6118")
	## A second, hatched part after the fill (a shortfall), as a share.
	var over:=0.0
	func _draw()->void:
		var r:=Rect2(Vector2.ZERO,size)
		draw_rect(r,Color(T.TRACK,0.75))
		var w:=size.x*clampf(ratio,0.0,1.0)
		if w>0.0:draw_rect(Rect2(0,0,maxf(1.0,w),size.y),color)
		if over>0.0:
			var ow:=size.x*clampf(over,0.0,1.0-clampf(ratio,0.0,1.0))
			draw_rect(Rect2(w,0,ow,size.y),Color(T.RED,0.55))
