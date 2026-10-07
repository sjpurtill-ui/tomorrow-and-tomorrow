extends "res://scripts/hud/settlement_overview.gd"
## THE CULTURE SCREEN, seen at a glance (hud/culture_model.gd). Pictures and
## numbers on the page; every explanation in its tooltip.
##   who we are: the picture, our name, our temper and how far our values agree;
##   what our ways do: a tile per lever (icon, word, bar either side of zero,
##     the number; hover for course vs values);
##   our course: one ribbon of the remembered courses by share;
##   what we live by: ten slim lines, lived (gold) and upheld (ring);
##   our leaders' temper: a five-pointed chart;
##   how others see us: the allure seal, its parts in one bar, and what it
##     brings (envoys, settlers, visitors).
## The daily refresh keeps the page while its rounded figures hold.
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Model:=preload("res://scripts/hud/culture_model.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

## Course colours, in ribbon order.
const RIBBON:=[Color("8a6118"),Color("356f66"),Color("695587"),Color("4d6389"),Color("805d1d"),Color("536d32")]
const PARTS:={"collection":["Collection",Color("8a6118")],"culture":["Shared ways",Color("356f66")],"values":["Open values",Color("4d6389")],"works":["Great works",Color("695587")]}

## A bar either side of a middle line: gains right (green), costs left (red).
class Diverging extends Control:
	var value:=0.0
	var span:=0.10
	func _init()->void:
		custom_minimum_size=Vector2(90,8)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		var mid:=size.x*0.5
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		var w:=clampf(absf(value)/maxf(0.001,span),0.0,1.0)*mid
		if value>=0.0: draw_rect(Rect2(Vector2(mid,0),Vector2(w,size.y)),T.GREEN)
		else: draw_rect(Rect2(Vector2(mid-w,0),Vector2(w,size.y)),T.RED)
		draw_line(Vector2(mid,-2),Vector2(mid,size.y+2),T.INK,1.0)

## A value's line: lived (gold dot) and upheld (ring), the gap shaded red.
class Spectrum extends Control:
	var lived:=0.5
	var official:=0.5
	func _init()->void:
		custom_minimum_size=Vector2(80,12)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		var y:=size.y*0.5
		draw_line(Vector2(0,y),Vector2(size.x,y),T.TRACK,3.0)
		var a:=lived*size.x
		var b:=official*size.x
		if absf(a-b)>2.0: draw_line(Vector2(minf(a,b),y),Vector2(maxf(a,b),y),Color(T.RED,0.6),4.0)
		draw_arc(Vector2(b,y),5.0,0.0,TAU,20,T.INK,1.5,true)
		draw_circle(Vector2(a,y),4.2,T.GOLD)

## Segments in a row, each its share and colour (shares of 1; the rest track).
class Ribbon extends Control:
	var parts:Array=[]   # [[share, colour]]
	func _init()->void:
		custom_minimum_size=Vector2(200,14)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		var total:=0.0
		for p:Array in parts: total+=float(p[0])
		var scale:=1.0/total if total>1.0 else 1.0
		var x:=0.0
		for p:Array in parts:
			var w:=size.x*float(p[0])*scale
			draw_rect(Rect2(Vector2(x,0),Vector2(w,size.y)),p[1])
			x+=w

## The people's temper: five sides as a five-pointed chart.
class Temper extends Control:
	var sides:Array=[]   # [{name, value, means}]
	func _init()->void:
		custom_minimum_size=Vector2(250,200)
		mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var n:=sides.size()
		if n<3: return
		var c:=size*0.5+Vector2(0,6)
		var r:=minf(size.x,size.y)*0.30
		var font:=T.font("ui")
		for ring in [0.5,1.0]:
			var pts:=PackedVector2Array()
			for i in n+1: pts.append(c+Vector2.from_angle(-PI*0.5+TAU*float(i%n)/float(n))*r*ring)
			draw_polyline(pts,T.RULE,1.0,true)
		var shape:=PackedVector2Array()
		for i in n:
			var dir:=Vector2.from_angle(-PI*0.5+TAU*float(i)/float(n))
			draw_line(c,c+dir*r,T.RULE,1.0)
			shape.append(c+dir*r*clampf(float(sides[i].value),0.0,1.0))
			var label:=String(sides[i].name)
			var at:=c+dir*(r+20.0)+Vector2(dir.x*12.0,0.0)
			var w:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
			draw_string(font,at-Vector2(w*0.5,-4),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,T.INK)
		draw_colored_polygon(shape,Color(T.GOLD,0.35))
		shape.append(shape[0])
		draw_polyline(shape,T.GOLD,2.0,true)
	func _get_tooltip(_at:Vector2)->String:
		var lines:PackedStringArray=[]
		for s:Dictionary in sides: lines.append("%s %d: the more, the more our leaders %s." % [String(s.name),roundi(float(s.value)*100.0),String(s.means)])
		return "\n".join(lines)

## A seal: a ring filled to the value, the number in it.
class Seal extends Control:
	var value:=0.0
	func _init()->void:
		custom_minimum_size=Vector2(88,88)
		mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		var c:=size*0.5
		var r:=minf(size.x,size.y)*0.5-6.0
		draw_arc(c,r,0.0,TAU,64,T.TRACK,7.0,true)
		draw_arc(c,r,-PI*0.5,-PI*0.5+TAU*clampf(value,0.0,1.0),64,T.GOLD,7.0,true)
		var font:=T.font("display")
		var text:=str(roundi(value*100.0))
		var w:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,26).x
		draw_string(font,c+Vector2(-w*0.5,9),text,HORIZONTAL_ALIGNMENT_LEFT,-1,26,T.INK)

var _print:Array=[]
var _columns:Array[GridContainer]=[]

func setup(block:Dictionary)->void:
	data=block;name="CulturePanel";add_theme_constant_override("separation",16)
	_print=page_print(block)
	_build()
	resized.connect(_layout)

## The live refresh: the page stays while its rounded figures hold.
func update_block(block:Dictionary)->bool:
	var next:=page_print(block)
	data=block
	if next==_print: return true
	_print=next
	# Hold the page's height while it is drawn again, so the reader's place
	# (the dock's scroll) is not lost to a moment's empty page.
	custom_minimum_size.y=size.y
	for child in get_children(): remove_child(child);child.queue_free()
	_columns.clear()
	_build()
	(func()->void: custom_minimum_size.y=0.0).call_deferred()
	return true

## What the page draws, rounded as it is shown.
static func page_print(block:Dictionary)->Array:
	var c:Dictionary=block.get("culture",{})
	var ledger:Array=[]
	for r:Dictionary in c.get("ledger",[]): ledger.append([String(r.id),roundi(float(r.course)*1000.0),roundi(float(r.values)*1000.0)])
	var values:Array=[]
	for v:Dictionary in c.get("values",[]): values.append([roundi(float(v.lived)*100.0),roundi(float(v.official)*100.0)])
	var remembered:Array=[]
	for r:Dictionary in (c.get("course",{}) as Dictionary).get("remembered",[]): remembered.append([String(r.id),roundi(float(r.share)*100.0)])
	var sides:Array=[]
	for s:Dictionary in (c.get("leaders",{}) as Dictionary).get("sides",[]): sides.append(roundi(float(s.value)*100.0))
	var others:Dictionary=c.get("others",{})
	return [String((c.get("identity",{}) as Dictionary).get("name","")),ledger,values,String((c.get("course",{}) as Dictionary).get("current","")),remembered,sides,
		String((c.get("leaders",{}) as Dictionary).get("work","")),roundi(float(others.get("allure",0.0))*100.0),roundi(float(others.get("integration_cost",0.0))*1000.0),
		roundi(float((c.get("alignment",{}) as Dictionary).get("alignment",0.0))*100.0),Portrait.Early.active()]

func _build()->void:
	var c:Dictionary=data.get("culture",{})
	_who(c)
	_ways(c)
	_course(c)
	_values(c)
	var lower:=HBoxContainer.new();lower.name="TemperAndOthers";lower.add_theme_constant_override("separation",24);add_child(lower)
	_temper(lower,c)
	_others(lower,c)
	_layout()

func _layout()->void:
	for grid in _columns:
		if not is_instance_valid(grid): continue
		if String(grid.name)=="Values": grid.columns=2 if size.x>=560 else 1
		else: grid.columns=3 if size.x>=760 else (2 if size.x>=480 else 1)

func _kicker(parent:Node,text:String,tip:String="")->Label:
	var label:=T.make_label(text,12,T.GOLD_TEXT)
	if tip!="": label.tooltip_text=tip;label.mouse_filter=Control.MOUSE_FILTER_PASS
	parent.add_child(label)
	return label

func _plain(parent:Node,text:String,size:int,color:Color)->Label:
	var label:=T.make_label(text,size,color)
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _chip(parent:Node,text:String,tip:String)->void:
	var chip:=PanelContainer.new();chip.tooltip_text=tip;chip.mouse_filter=Control.MOUSE_FILTER_STOP
	chip.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.BORDER_SOFT,1,T.RADIUS_CONTROL,6.0))
	parent.add_child(chip)
	_plain(chip,text,13,T.INK)

# --- Who we are ------------------------------------------------------------------

func _who(c:Dictionary)->void:
	var identity:Dictionary=c.get("identity",{})
	var row:=HBoxContainer.new();row.name="Who";row.add_theme_constant_override("separation",18);add_child(row)
	var image:=TextureRect.new();image.texture=Visuals.art("culture");image.custom_minimum_size=Vector2(132,104)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if Portrait.Early.active():
		image.texture=Portrait.Early.civic_scene(data.get("lived_values",{}))
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.tooltip_text="Most of all: %s." % String(identity.get("summary","")).to_lower()
	row.add_child(image)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.alignment=BoxContainer.ALIGNMENT_CENTER;words.add_theme_constant_override("separation",10);row.add_child(words)
	var name:=_serif(String(identity.get("name","")).capitalize(),26);name.tooltip_text=image.tooltip_text;name.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(name)
	var chips:=HFlowContainer.new();chips.add_theme_constant_override("h_separation",8);chips.add_theme_constant_override("v_separation",6);words.add_child(chips)
	var leaders:Dictionary=c.get("leaders",{})
	_chip(chips,"Temper: %s" % String(leaders.get("temperament","")).to_lower(),"Our people's temper, read from the values they live by. Our leaders act by it wherever you do not decide.")
	var a:Dictionary=c.get("alignment",{})
	_chip(chips,"Values agree %d in 100" % roundi(float(a.get("alignment",0.0))*100.0),"How far what the people live by matches what is upheld over them: cohesion %s, legitimacy %s." % [Model.pct(float(a.get("cohesion",0.0))),Model.pct(float(a.get("legitimacy",0.0)))])
	_chip(chips,"Allure %d" % roundi(float((c.get("others",{}) as Dictionary).get("allure",0.0))*100.0),"How much other peoples want to come to us, trade with us and learn from us (of 100).")

# --- What our ways do --------------------------------------------------------------

func _ways(c:Dictionary)->void:
	_kicker(self,"WHAT OUR WAYS DO","Every lever our course and our values move now. Hover a tile for where it comes from.")
	var rows:Array=c.get("ledger",[])
	if rows.is_empty():
		_plain(self,"Nothing yet",13,T.MUTED);return
	var span:=0.05
	for r:Dictionary in rows: span=maxf(span,absf(float(r.total)))
	var grid:=GridContainer.new();grid.name="Ledger";grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",8);add_child(grid);_columns.append(grid)
	for r:Dictionary in rows:
		var tile:=HBoxContainer.new();tile.add_theme_constant_override("separation",8);tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tile.mouse_filter=Control.MOUSE_FILTER_STOP
		var parts:PackedStringArray=[]
		if absf(float(r.course))>=0.004: parts.append("course %s" % Model.pct(float(r.course)))
		if absf(float(r.values))>=0.004: parts.append("values %s" % Model.pct(float(r.values)))
		tile.tooltip_text="%s %s: %s." % [String(r.label),Model.pct(float(r.total)),", ".join(parts)]
		grid.add_child(tile)
		var gain:=float(r.total)>=0.0
		var icon:=TextureRect.new();icon.texture=Icons.domain_texture(String(r.icon),T.GREEN if gain else T.RED);icon.custom_minimum_size=Vector2(22,22)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.add_child(icon)
		var word:=_plain(tile,String(r.short),14,T.INK);word.custom_minimum_size.x=84
		var bar:=Diverging.new();bar.value=float(r.total);bar.span=span;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tile.add_child(bar)
		var number:=_plain(tile,Model.pct(float(r.total)),14,T.GREEN_TEXT if gain else T.RED_TEXT);number.custom_minimum_size.x=46;number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

# --- Our course ----------------------------------------------------------------------

func _course(c:Dictionary)->void:
	var course:Dictionary=c.get("course",{})
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",12);add_child(head)
	var k:=_kicker(head,"OUR COURSE");k.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var name:=_serif(String(course.get("name","")),20);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name.tooltip_text=String(course.get("vision",""));name.mouse_filter=Control.MOUSE_FILTER_PASS;head.add_child(name)
	if data.get("on_direction") is Callable:
		_button(head,"Review",data.on_direction,"The century's course: chosen again at each century's turn")
		(head.get_child(head.get_child_count()-1) as Control).size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var remembered:Array=course.get("remembered",[])
	if remembered.is_empty(): return
	var ribbon:=Ribbon.new();ribbon.name="CourseRibbon";ribbon.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var legend:=HFlowContainer.new();legend.add_theme_constant_override("h_separation",16)
	for i in mini(remembered.size(),RIBBON.size()):
		var r:Dictionary=remembered[i]
		ribbon.parts.append([float(r.share),RIBBON[i]])
		var item:=HBoxContainer.new();item.add_theme_constant_override("separation",6);item.mouse_filter=Control.MOUSE_FILTER_STOP
		item.tooltip_text="%s · %d in 100 of our memory (older courses fade by half every 60 years).\nAt full strength: %s" % [String(r.name),roundi(float(r.share)*100.0),String(r.does)]
		var swatch:=ColorRect.new();swatch.color=RIBBON[i];swatch.custom_minimum_size=Vector2(10,10);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(swatch)
		_plain(item,"%s %d" % [String(r.name),roundi(float(r.share)*100.0)],13,T.INK if bool(r.current) else T.MUTED)
		legend.add_child(item)
	add_child(ribbon);add_child(legend)

# --- What we live by ---------------------------------------------------------------

func _values(c:Dictionary)->void:
	_kicker(self,"WHAT WE LIVE BY","Gold: where the people live. Ring: what is upheld over them. A red stretch is a gap that costs cohesion and trust in those who rule.")
	var grid:=GridContainer.new();grid.name="Values";grid.add_theme_constant_override("h_separation",24);grid.add_theme_constant_override("v_separation",6);add_child(grid);_columns.append(grid)
	for v:Dictionary in c.get("values",[]):
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);line.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.mouse_filter=Control.MOUSE_FILTER_STOP
		line.tooltip_text="%s (%s to %s): %s" % [String(v.name),String(v.low).to_lower(),String(v.high).to_lower(),String(v.meaning)]
		grid.add_child(line)
		var lo:=_plain(line,String(v.get("low_word",_word(String(v.low)))),12,T.MUTED);lo.custom_minimum_size.x=78
		var bar:=Spectrum.new();bar.lived=float(v.lived);bar.official=float(v.official);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(bar)
		var hi:=_plain(line,String(v.get("high_word",_word(String(v.high)))),12,T.MUTED);hi.custom_minimum_size.x=78;hi.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

## One word for a pole: its last word, which carries it ("Equal Standing").
static func _word(pole:String)->String:
	var words:=pole.split(" ",false)
	return String(words[words.size()-1]) if not words.is_empty() else pole

# --- Temper and others -------------------------------------------------------------

func _temper(parent:Node,c:Dictionary)->void:
	var leaders:Dictionary=c.get("leaders",{})
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",4);parent.add_child(box)
	_kicker(box,"OUR LEADERS' TEMPER","Where you do not decide, our leaders act by this temper: the daily work, what is studied, how fast we grow.")
	var chart:=Temper.new();chart.name="TemperChart";chart.sides=leaders.get("sides",[]);box.add_child(chart)
	var work:=_plain(box,_short_work(String(leaders.get("work",""))),13,T.BODY)
	work.tooltip_text=String(leaders.get("work_tip",""));work.mouse_filter=Control.MOUSE_FILTER_PASS

## "Our leaders keep the work balanced, favouring no one task." -> "Keep the
## work balanced, favouring no one task".
static func _short_work(line:String)->String:
	if line=="": return ""
	var s:=line.trim_prefix("Our leaders ").trim_suffix(".")
	return s.left(1).to_upper()+s.substr(1)

func _others(parent:Node,c:Dictionary)->void:
	var o:Dictionary=c.get("others",{})
	var box:=VBoxContainer.new();box.name="Others";box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",10);parent.add_child(box)
	_kicker(box,"HOW OTHERS SEE US")
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",14);box.add_child(top)
	var seal:=Seal.new();seal.value=float(o.get("allure",0.0));seal.tooltip_text="Allure %d in 100 (%s): how much other peoples want to come to us, trade with us and learn from us." % [roundi(float(o.get("allure",0.0))*100.0),String(o.get("label","")).to_lower()];top.add_child(seal)
	var right:=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.alignment=BoxContainer.ALIGNMENT_CENTER;right.add_theme_constant_override("separation",6);top.add_child(right)
	var ribbon:=Ribbon.new();ribbon.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_child(ribbon)
	var legend:=HFlowContainer.new();legend.add_theme_constant_override("h_separation",12);right.add_child(legend)
	for p:Dictionary in o.get("parts",[]):
		var spec:Array=PARTS.get(String(p.source),[String(p.source),T.MUTED])
		ribbon.parts.append([float(p.value),spec[1]])
		var item:=HBoxContainer.new();item.add_theme_constant_override("separation",5);item.mouse_filter=Control.MOUSE_FILTER_STOP;item.tooltip_text=String(p.text)
		var swatch:=ColorRect.new();swatch.color=spec[1];swatch.custom_minimum_size=Vector2(10,10);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(swatch)
		_plain(item,"%s +%d" % [String(spec[0]),roundi(float(p.value)*100.0)],12,T.INK)
		legend.add_child(item)
	# What allure brings: three figures.
	var tiles:=HBoxContainer.new();tiles.add_theme_constant_override("separation",10);box.add_child(tiles)
	for e:Dictionary in o.get("effects",[]):
		var figure:=""
		var label:=""
		match String(e.get("target","")):
			"diplomacy": figure="+%.2f" % float(e.value);label="Envoys"
			"migration": figure=Model.pct(float(e.value));label="Settlers"
			"museum": figure="×%.2f" % (1.0+float(e.value));label="Visitors"
			_: continue
		_tile(tiles,figure,label,String(e.text))
	if float(o.get("unsettled",0.0))>=1.0:
		_tile(tiles,Model.pct(-float(o.get("integration_cost",0.0))),"Newcomers","%d newcomers not yet settled cost this much of how close our people hold, until they settle." % roundi(float(o.unsettled)),true)
	if data.has("artifacts"):
		var open:Variant=(data.artifacts as Dictionary).get("on_open")
		if open is Callable: _button(box,"Open the collection",open,"The pieces we hold, study and exhibit")

func _tile(parent:Node,figure:String,label:String,tip:String,warn:bool=false)->void:
	var tile:=PanelContainer.new();tile.tooltip_text=tip;tile.mouse_filter=Control.MOUSE_FILTER_STOP;tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel",T.flat(T.ROW_BG,T.RED if warn else T.BORDER_SOFT,1,T.RADIUS_CONTROL,8.0))
	parent.add_child(tile)
	var col:=VBoxContainer.new();col.add_theme_constant_override("separation",0);tile.add_child(col)
	var big:=_plain(col,figure,20,T.RED_TEXT if warn else T.INK);big.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var small:=_plain(col,label.to_upper(),12,T.MUTED);small.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
