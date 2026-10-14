extends RefCounted
## The Economy pages' shared parts, so every tab reads the same way:
##   compatible dock readings, open rows with a name and value above their
##   explanation, quiet state tags and full-sized commands, and grids that
##   flow into two or three columns on a wide page.
## Every builder returns the nodes a live refresh writes into, so a page can
## keep its nodes (and an open tooltip) while the day's numbers change.
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
## The shared strategy-screen blocks: their verb, tag and bar are ours too.
const Dense:=preload("res://scripts/hud/dense_blocks.gd")

const ROW_HEIGHT:=48.0
const ICON_SIZE:=24.0

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
	var l:=label(text,size,color,true)
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
	var l:=label(text,14,T.legible(color,T.DOCK_BG),true)
	var style:=T.flat(Color(color,0.14),Color(color,0.6),1,8,0)
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
		style=style.duplicate();style.bg_color=Color(color,0.14);style.border_color=Color(color,0.6);l.add_theme_stylebox_override("normal",style)

## A small verb button ("Build", "Ask", "Show"): on the row or beside the
## figure it changes. `chosen` marks the current one of a set of choices.
static func verb(text:String,callback:Variant,tip:String="",chosen:=false,primary:=false)->Button:
	var b:=Dense.verb(text,callback,tip,not (callback is Callable and (callback as Callable).is_valid()))
	T.apply_button_style(b,primary)
	if chosen and not primary:
		b.add_theme_stylebox_override("normal",b.get_theme_stylebox("pressed").duplicate())
	return b

## A sans section head; `right` is a short
## figure or note at the head's far end.
static func head(parent:Node,text:String,right:String="",tip:String="")->Dictionary:
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8);parent.add_child(box)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);box.add_child(row)
	var title:=label(text,24,T.INK,true);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.tooltip_text=tip;row.add_child(title)
	var side:=label(right,14,T.INK_MUTED);side.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(side)
	return {"box":box,"row":row,"title":title,"side":side}

## A grid that holds rows in 1 to `most` columns by the width it is given
## (`min_column` px a column). Call flow() from the page's resized signal.
static func columns(parent:Node,node_name:String,min_column:float=380.0,most:int=2)->GridContainer:
	var grid:=GridContainer.new();grid.name=node_name;grid.columns=1;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",8)
	grid.set_meta("min_column",min_column);grid.set_meta("most",most)
	parent.add_child(grid)
	return grid

static func flow(grid:GridContainer,width:float)->void:
	if grid==null or not is_instance_valid(grid):return
	var columns:=clampi(floori((width+22.0)/(float(grid.get_meta("min_column",380.0))+22.0)),1,int(grid.get_meta("most",2)))
	# Never more columns than the widest row allows: the page is never pushed wider.
	var widest:=0.0
	for child in grid.get_children():
		if child is Control and (child as Control).visible:widest=maxf(widest,(child as Control).get_combined_minimum_size().x)
	while columns>1 and widest*columns+22.0*(columns-1)>width:columns-=1
	if grid.columns!=columns:grid.columns=columns

# --------------------------------------------------------------------------
# The KPI strip
# --------------------------------------------------------------------------

## A strip figure with its id, for kpi lists a provider hands the dock.
static func kpi_item(id:String,item:Dictionary)->Dictionary:
	var out:=item.duplicate();out.id=id
	return out

## Strip figures in the dock's own form (dock_panel.gd _rebuild_kpis): a big
## number, its bar against the stated maximum, the few words under it, the
## reckoning in the pointer. `labels` names each id.
static func dock_kpis(items:Array,labels:Dictionary)->Array:
	var out:Array=[]
	for item:Dictionary in items:
		var kpi:={"label":String(labels.get(String(item.get("id","")),item.get("label",""))).to_upper(),"value":String(item.get("value","")),"glance":true,"delta":String(item.get("sub","")),"tip":String(item.get("tip",""))}
		if item.has("sub_color"):kpi.delta_color=item.sub_color
		var ratio:=float(item.get("ratio",-1.0))
		if ratio>=0.0:kpi.meter=clampf(ratio,0.0,1.0);kpi.meter_color=item.get("color",T.GOLD)
		if item.get("on_press") is Callable:kpi.on_press=item.on_press
		out.append(kpi)
	return out

# --------------------------------------------------------------------------
# Open rows
# --------------------------------------------------------------------------

## A fact's name and value lead; notes, signals and actions follow below.
## item: {icon, icon_kind, label, value, value_color, ratio (-1 none),
## bar_color, bar_width, note (small grey text after the label), tag,
## tag_color, tip, buttons:[{text,on_press,tip,chosen,primary,disabled}]}.
static func row(parent:Node,item:Dictionary)->Dictionary:
	var panel:=PanelContainer.new();panel.name="Row_"+String(item.get("id",item.get("label",""))).validate_node_name()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=StyleBoxFlat.new();style.bg_color=Color.TRANSPARENT;style.border_width_bottom=1;style.border_color=Color(T.RULE,0.45)
	style.content_margin_top=10;style.content_margin_bottom=10;style.content_margin_left=0;style.content_margin_right=0
	panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);line.custom_minimum_size.y=ROW_HEIGHT;line.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(line)
	var key:=String(item.get("icon",""))
	var glyph:TextureRect=null
	if item.has("icon"):glyph=icon(key,ICON_SIZE,String(item.get("icon_kind","resource")));line.add_child(glyph)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",6);line.add_child(body)
	var headline:=HBoxContainer.new();headline.add_theme_constant_override("separation",8);body.add_child(headline)
	var name_label:=label(String(item.get("label","")),16,T.INK,true);name_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# The name is always whole (it wraps on a narrow page, never cut short);
	# it takes its share of a wide row.
	name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;name_label.custom_minimum_size.x=80
	name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.size_flags_stretch_ratio=float(item.get("label_width",150.0))/150.0
	headline.add_child(name_label)
	var value:=label("",20,T.INK,true);value.size_flags_vertical=Control.SIZE_SHRINK_CENTER;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;value.custom_minimum_size.x=minf(96.0,float(item.get("value_width",72.0)));value.mouse_filter=Control.MOUSE_FILTER_IGNORE;headline.add_child(value)
	var note:=label("",14,T.INK_MUTED);note.size_flags_horizontal=Control.SIZE_EXPAND_FILL;note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(note)
	var signals:=HFlowContainer.new();signals.add_theme_constant_override("h_separation",12);signals.add_theme_constant_override("v_separation",6);body.add_child(signals)
	var spark:Control=null
	if item.has("points"):
		spark=preload("res://scripts/hud/material_stock_spark.gd").new();spark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;spark.mouse_filter=Control.MOUSE_FILTER_IGNORE;signals.add_child(spark)
		var spark_width:=float(item.get("bar_width",70.0))
		spark.ready.connect(func()->void:spark.custom_minimum_size=Vector2(spark_width,22);spark.mouse_filter=Control.MOUSE_FILTER_IGNORE;spark.tooltip_text="")
	var meter:=bar(0.0,T.GOLD,float(item.get("bar_width",70.0)),5.0);meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;signals.add_child(meter)
	var state:=tag("",T.MUTED);state.mouse_filter=Control.MOUSE_FILTER_IGNORE;signals.add_child(state)
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",8);actions.add_theme_constant_override("v_separation",8);actions.visible=not (item.get("buttons",[]) as Array).is_empty();(headline if bool(item.get("compact_actions",false)) else body).add_child(actions)
	var buttons:Array=[]
	for spec:Dictionary in item.get("buttons",[]):
		var b:=verb(String(spec.get("text","")),spec.get("on_press"),String(spec.get("tip","")),bool(spec.get("chosen",false)),bool(spec.get("primary",false)))
		if bool(spec.get("disabled",false)):b.disabled=true
		actions.add_child(b);buttons.append(b)
	var refs:={"panel":panel,"label":name_label,"note":note,"bar":meter,"value":value,"tag":state,"buttons":buttons,"icon":glyph,"spark":spark,"signals":signals,"compact":false}
	panel.set_meta("econ_row",refs)
	set_row(refs,item)
	return refs

static func set_row(refs:Dictionary,item:Dictionary)->void:
	put(refs.label,String(item.get("label","")),item.get("label_color",T.INK))
	put(refs.note,String(item.get("note","")),item.get("note_color",T.INK_MUTED))
	put(refs.value,String(item.get("value","")),item.get("value_color",T.INK))
	var ratio:=float(item.get("ratio",-1.0))
	var meter:Bar=refs.bar
	meter.visible=ratio>=0.0 and not bool(refs.get("compact",false))
	(refs.note as Control).visible=not String(item.get("note","")).is_empty()
	refs.ratio=ratio
	var color:Color=item.get("bar_color",T.GOLD)
	if ratio>=0.0 and (meter.ratio!=ratio or meter.color!=color):meter.ratio=ratio;meter.color=color;meter.queue_redraw()
	set_tag(refs.tag,String(item.get("tag","")),item.get("tag_color",T.MUTED))
	var spark:Control=refs.get("spark")
	(refs.signals as Control).visible=meter.visible or (refs.tag as Control).visible or (spark!=null and spark.visible)
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
		draw_rect(r,Color(T.INK,0.12))
		var w:=size.x*clampf(ratio,0.0,1.0)
		if w>0.0:draw_rect(Rect2(0,0,maxf(1.0,w),size.y),color)
		if over>0.0:
			var ow:=size.x*clampf(over,0.0,1.0-clampf(ratio,0.0,1.0))
			draw_rect(Rect2(w,0,ow,size.y),Color(T.RED,0.55))

## Narrow rows retain their explanation and controls. Optional graphical
## signals stay in the row's pointer. Call from the page's resize.
const COMPACT_BELOW:=460.0
static func compact(root:Node,width:float)->void:
	if width<=0.0:return
	var narrow:=width<COMPACT_BELOW
	for node in root.find_children("*","PanelContainer",true,false):
		if not node.has_meta("econ_row"):continue
		var refs:Dictionary=node.get_meta("econ_row")
		if bool(refs.get("compact",false))==narrow:continue
		refs.compact=narrow
		if narrow:(refs.bar as Control).visible=false
		else:(refs.bar as Control).visible=float(refs.get("ratio",-1.0))>=0.0
		if refs.get("spark")!=null:(refs.spark as Control).visible=not narrow
		(refs.signals as Control).visible=(refs.bar as Control).visible or (refs.tag as Control).visible or (refs.get("spark")!=null and (refs.spark as Control).visible)
