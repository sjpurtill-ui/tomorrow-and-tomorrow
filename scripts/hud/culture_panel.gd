extends "res://scripts/hud/settlement_overview.gd"
## Culture's current course and exact effects, with all ten paired value axes.
## The selected value supplies the explanation beneath the comparison grid.
## The leaders' temper and allure context keep their original model and actions.
## Updates preserve the selected value and focused control.
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const Model:=preload("res://scripts/hud/culture_model.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

## Course colours, in ribbon order.
static func ribbon_colors()->Array[Color]:
	return [T.GOLD,T.TEAL,T.VIOLET,T.BLUE,T.AMBER,T.GREEN]

static func allure_parts()->Dictionary:
	return {"collection":["Collection",T.GOLD],"culture":["Shared ways",T.TEAL],"values":["Open values",T.BLUE],"works":["Great works",T.VIOLET]}

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
		var font:=T.font("ui_strong")
		var text:=str(roundi(value*100.0))
		var w:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,26).x
		draw_string(font,c+Vector2(-w*0.5,9),text,HORIZONTAL_ALIGNMENT_LEFT,-1,26,T.INK)

var _print:Array=[]
var _columns:Array[GridContainer]=[]
var selected_value:=""
var value_grid:GridContainer
var value_refs:Dictionary={}
var value_reader:VBoxContainer

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
	var before_other:=_print.duplicate(true);var after_other:=next.duplicate(true)
	before_other[2]=[];after_other[2]=[]
	_print=next
	if before_other==after_other:
		_fill_value();return true
	var saved_view:=preload("res://scripts/hud/view_state.gd").capture(self)
	# Hold the page's height while it is drawn again, so the reader's place
	# (the dock's scroll) is not lost to a moment's empty page.
	custom_minimum_size.y=size.y
	for child in get_children(): remove_child(child);child.queue_free()
	_columns.clear()
	_build()
	preload("res://scripts/hud/view_state.gd").restore(self,saved_view)
	(func()->void: custom_minimum_size.y=0.0).call_deferred()
	return true

## What the page draws, rounded as it is shown.
static func page_print(block:Dictionary)->Array:
	var c:Dictionary=block.get("culture",{})
	var ledger:Array=[]
	for r:Dictionary in c.get("ledger",[]): ledger.append([String(r.id),roundi(float(r.course)*1000.0),roundi(float(r.values)*1000.0)])
	var values:Array=[]
	for v:Dictionary in c.get("values",[]): values.append([roundi(float(v.lived)*100.0),roundi(float(v.official)*100.0),v.get("family_lived",0),v.get("family_official",0),v.get("favored_family",""),v.get("favored_target")])
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
	_course(c)
	_ways(c)
	var lower:=BoxContainer.new();lower.name="ValuesAndTemper";lower.add_theme_constant_override("separation",24);add_child(lower)
	var values:=VBoxContainer.new();values.size_flags_horizontal=Control.SIZE_EXPAND_FILL;values.size_flags_stretch_ratio=1.4;values.add_theme_constant_override("separation",12);lower.add_child(values)
	_values(c,values)
	_temper(lower,c)
	_others(self,c)
	_layout()

func _layout()->void:
	var lower:=get_node_or_null("ValuesAndTemper") as BoxContainer
	if lower:lower.vertical=size.x<700
	for grid in _columns:
		if not is_instance_valid(grid): continue
		if String(grid.name)=="Values": grid.columns=2 if size.x>=560 else 1
		else: grid.columns=3 if size.x>=900 else (2 if size.x>=640 else 1)

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
	chip.add_theme_stylebox_override("panel",T.flat(Color.TRANSPARENT,T.BORDER_SOFT,0,0,0))
	parent.add_child(chip)
	_plain(chip,text,14,T.MUTED)

# --- Who we are ------------------------------------------------------------------

func _who(c:Dictionary)->void:
	var identity:Dictionary=c.get("identity",{})
	var row:=HBoxContainer.new();row.name="Who";row.add_theme_constant_override("separation",18);add_child(row)
	var image:=TextureRect.new();image.texture=Visuals.art("culture");image.custom_minimum_size=Vector2(56,44)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if Portrait.Early.active():
		image.texture=Portrait.Early.civic_scene(data.get("lived_values",{}))
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.tooltip_text="Most of all: %s." % String(identity.get("summary","")).to_lower()
	row.add_child(image)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.alignment=BoxContainer.ALIGNMENT_CENTER;words.add_theme_constant_override("separation",10);row.add_child(words)
	var name:=_serif(String(identity.get("name","")).capitalize(),32);name.tooltip_text=image.tooltip_text;name.mouse_filter=Control.MOUSE_FILTER_PASS;words.add_child(name)
	var chips:=HFlowContainer.new();chips.add_theme_constant_override("h_separation",20);chips.add_theme_constant_override("v_separation",8);words.add_child(chips)
	var leaders:Dictionary=c.get("leaders",{})
	_chip(chips,"Temper: %s" % String(leaders.get("temperament","")).to_lower(),"Our people's temper, read from the values they live by. Our leaders act by it wherever you do not decide.")
	var a:Dictionary=c.get("alignment",{})
	_chip(chips,"Values agree %d in 100" % roundi(float(a.get("alignment",0.0))*100.0),"How far what the people live by matches what is upheld over them: cohesion %s, legitimacy %s." % [effect_amount("cohesion",float(a.get("cohesion",0.0))),effect_amount("legitimacy",float(a.get("legitimacy",0.0)))])
	# Our ways' own allure: one named part of Standing's draw (World shows the draw, this among its parts).
	_chip(chips,"Our ways' allure %d" % roundi(float((c.get("others",{}) as Dictionary).get("allure",0.0))*100.0),"How much our ways themselves make other peoples want to come to us, trade with us and learn from us (of 100). It is one named part of Standing's draw (World shows the draw and each of its parts).")

# --- What our ways do --------------------------------------------------------------

static func effect_amount(id:String,amount:float)->String:
	# These readings add to normalized condition/capacity targets, rather than
	# multiplying output. Display units only; the model's amount is unchanged.
	var text:=Model.pct(amount)
	return text.replace("%"," pts") if id in ["cohesion","legitimacy","institutions","security","health","carrying","trade"] else text

func _ways(c:Dictionary)->void:
	_kicker(self,"WHAT OUR WAYS DO","Current effects of our course and values. Hover an effect for its source.")
	var rows:Array=c.get("ledger",[])
	if rows.is_empty():
		_plain(self,"Nothing yet",13,T.MUTED);return
	var grid:=HFlowContainer.new();grid.name="Ledger";grid.add_theme_constant_override("h_separation",20);grid.add_theme_constant_override("v_separation",8);add_child(grid)
	var tendencies:PackedStringArray=[]
	for r:Dictionary in rows:
		var inactive_values:=String(r.id) in ["adoption","trade"]
		var amount:=float(r.course) if inactive_values else float(r.total)
		if inactive_values and absf(float(r.values))>=0.004:tendencies.append("%s %s" % [r.short,Model.pct(float(r.values))])
		if inactive_values and absf(amount)<0.004:continue
		var tile:=HBoxContainer.new();tile.add_theme_constant_override("separation",8);tile.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;tile.mouse_filter=Control.MOUSE_FILTER_STOP
		var parts:PackedStringArray=[]
		if absf(float(r.course))>=0.004:parts.append("course %s" % effect_amount(String(r.id),float(r.course)))
		if not inactive_values and absf(float(r.values))>=0.004:parts.append("values %s" % effect_amount(String(r.id),float(r.values)))
		tile.tooltip_text="%s %s: %s." % [String(r.label),effect_amount(String(r.id),amount),", ".join(parts)]
		grid.add_child(tile)
		var gain:=amount>=0.0
		var icon:=TextureRect.new();icon.texture=Icons.domain_texture(String(r.icon),T.GREEN if gain else T.RED);icon.custom_minimum_size=Vector2(22,22)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.add_child(icon)
		_plain(tile,String(r.short),14,T.INK)
		_plain(tile,effect_amount(String(r.id),amount),16,T.GREEN_TEXT if gain else T.RED_TEXT)
	if not tendencies.is_empty():
		var note:=_plain(self,"Values lean toward: %s. These tendencies have no current bonus." % " · ".join(tendencies),14,T.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

# --- Our course ----------------------------------------------------------------------

func _course(c:Dictionary)->void:
	var course:Dictionary=c.get("course",{})
	var section:=VBoxContainer.new();section.add_theme_constant_override("separation",4);add_child(section)
	var head:=HFlowContainer.new();head.add_theme_constant_override("h_separation",12);head.add_theme_constant_override("v_separation",6);section.add_child(head)
	var k:=_kicker(head,"OUR COURSE");k.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var name:=_serif(String(course.get("name","")),20);name.autowrap_mode=TextServer.AUTOWRAP_OFF;name.tooltip_text=String(course.get("vision",""));name.mouse_filter=Control.MOUSE_FILTER_PASS;head.add_child(name)
	if data.get("on_direction") is Callable:
		_button(head,"Review",data.on_direction,"The century's course: chosen again at each century's turn")
		(head.get_child(head.get_child_count()-1) as Control).size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var remembered:Array=course.get("remembered",[])
	if remembered.is_empty(): return
	if remembered.size()==1:
		var memory:Dictionary=remembered[0]
		var share:=_plain(section,"%d in 100 of our memory follows this course" % roundi(float(memory.share)*100.0),14,T.MUTED)
		share.mouse_filter=Control.MOUSE_FILTER_PASS;share.tooltip_text="%s · older courses fade by half every 60 years.\nAt full strength: %s" % [String(memory.name),String(memory.does)]
		return
	var colors:=ribbon_colors()
	var ribbon:=Ribbon.new();ribbon.name="CourseRibbon";ribbon.custom_minimum_size.y=5;ribbon.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var legend:=HFlowContainer.new();legend.add_theme_constant_override("h_separation",16)
	for i in mini(remembered.size(),colors.size()):
		var r:Dictionary=remembered[i]
		ribbon.parts.append([float(r.share),colors[i]])
		var item:=HBoxContainer.new();item.add_theme_constant_override("separation",6);item.mouse_filter=Control.MOUSE_FILTER_STOP
		item.tooltip_text="%s · %d in 100 of our memory (older courses fade by half every 60 years).\nAt full strength: %s" % [String(r.name),roundi(float(r.share)*100.0),String(r.does)]
		var swatch:=ColorRect.new();swatch.color=colors[i];swatch.custom_minimum_size=Vector2(10,10);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(swatch)
		_plain(item,"%s %d" % [String(r.name),roundi(float(r.share)*100.0)],13,T.INK if bool(r.current) else T.MUTED)
		legend.add_child(item)
	section.add_child(ribbon);section.add_child(legend)

# --- What we live by ---------------------------------------------------------------

func view_state()->Dictionary:
	return {"value":selected_value}

func restore_view_state(state:Dictionary)->void:
	selected_value=String(state.get("value",selected_value));_fill_value()

func _values(c:Dictionary,parent:Node)->void:
	_kicker(parent,"WHAT WE LIVE BY")
	_plain(parent,"● Lived practice   ○ Official position · 0–100",13,T.MUTED)
	value_grid=GridContainer.new();value_grid.name="ValueAxes";value_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;value_grid.add_theme_constant_override("h_separation",22);value_grid.add_theme_constant_override("v_separation",10);parent.add_child(value_grid)
	value_grid.resized.connect(func():value_grid.columns=2 if value_grid.size.x>=600 else 1)
	value_refs.clear()
	var values:Array=c.get("values",[])
	var widest:Dictionary={}
	for v:Dictionary in values:
		if widest.is_empty() or float(v.gap)>float(widest.gap):widest=v
	if selected_value=="" and not widest.is_empty():selected_value=String(widest.axis)
	for v:Dictionary in values:
		var id:=String(v.axis)
		var cell:=VBoxContainer.new();cell.name="Axis_"+id;cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",4);value_grid.add_child(cell)
		var button:=Button.new();button.name="SelectValue_"+id;button.toggle_mode=true;button.alignment=HORIZONTAL_ALIGNMENT_LEFT;T.apply_button_style(button);cell.add_child(button)
		button.pressed.connect(func():selected_value=id;_fill_value())
		var bar:=Spectrum.new();bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_child(bar)
		var poles:=HBoxContainer.new();cell.add_child(poles)
		var low:=_plain(poles,String(v.low_word),12,T.MUTED);low.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_plain(poles,String(v.high_word),12,T.MUTED)
		value_refs[id]={"button":button,"bar":bar,"cell":cell}
	value_reader=VBoxContainer.new();value_reader.name="Values";value_reader.add_theme_constant_override("separation",8);parent.add_child(value_reader)
	_fill_value()

func _fill_value()->void:
	if value_reader==null:return
	for value:Dictionary in data.get("culture",{}).get("values",[]):
		var id:=String(value.axis)
		if not value_refs.has(id):continue
		var refs:Dictionary=value_refs[id]
		refs.button.text="%s   ● %d   ○ %d" % [String(value.name),roundi(float(value.lived)*100),roundi(float(value.official)*100)]
		refs.button.set_pressed_no_signal(id==selected_value)
		refs.bar.lived=float(value.lived);refs.bar.official=float(value.official);refs.bar.queue_redraw()
		refs.cell.tooltip_text="%s\nLived %d · official %d · gap %d in 100" % [String(value.meaning),roundi(float(value.lived)*100),roundi(float(value.official)*100),roundi(float(value.gap)*100)]
	for child in value_reader.get_children():value_reader.remove_child(child);child.queue_free()
	var chosen:Dictionary={}
	for v:Dictionary in data.get("culture",{}).get("values",[]):
		if String(v.axis)==selected_value:chosen=v;break
	if chosen.is_empty():return
	var words:=_plain(value_reader,String(chosen.meaning),16,T.BODY);words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var line:=HBoxContainer.new();line.add_theme_constant_override("separation",12);value_reader.add_child(line)
	_plain(line,String(chosen.low),14,T.MUTED)
	var bar:=Spectrum.new();bar.lived=float(chosen.lived);bar.official=float(chosen.official);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(bar)
	_plain(line,String(chosen.high),14,T.MUTED)
	var readings:=HFlowContainer.new();readings.add_theme_constant_override("h_separation",20);readings.add_theme_constant_override("v_separation",6);value_reader.add_child(readings)
	_plain(readings,"People live %d · upheld %d" % [roundi(float(chosen.lived)*100),roundi(float(chosen.official)*100)],14,T.INK).name="ValueReadings"
	_plain(readings,"Gap %d in 100" % roundi(float(chosen.gap)*100),14,T.RED_TEXT if float(chosen.gap)>0.05 else T.MUTED)
	var family_lived:=float(chosen.get("family_lived",0))*100
	var family_official:=float(chosen.get("family_official",0))*100
	if not is_zero_approx(family_lived) or not is_zero_approx(family_official):
		_plain(value_reader,"Recorded family movement · lived %+.1f pts · official %+.1f pts" % [family_lived,family_official],13,T.MUTED).tooltip_text="Cumulative recorded shifts from family influence, including past favored heads. Not a forecast or the entire cause of today's values."
	if chosen.get("favored_target")!=null:
		var family_words:=_plain(value_reader,"%s favors %d on this axis" % [String(chosen.get("favored_family","")),roundi(float(chosen.favored_target)*100)],14,T.GOLD_TEXT)
		family_words.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	value_reader.tooltip_text="Gold dot: where people live. Ring: what is upheld over them. The gap costs cohesion and trust in those who rule. Values run from 0 at %s to 100 at %s." % [chosen.low,chosen.high]

## One word for a pole: its last word, which carries it ("Equal Standing").
static func _word(pole:String)->String:
	var words:=pole.split(" ",false)
	return String(words[words.size()-1]) if not words.is_empty() else pole

# --- Temper and others -------------------------------------------------------------

func _temper(parent:Node,c:Dictionary)->void:
	var leaders:Dictionary=c.get("leaders",{})
	var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_theme_constant_override("separation",4);parent.add_child(box)
	_kicker(box,"OUR LEADERS' TEMPER","Where you do not decide, our leaders act by this temper: the daily work, what is studied, how fast we grow.")
	var chart:=Temper.new();chart.name="TemperChart";chart.sides=leaders.get("sides",[]);box.add_child(chart)
	var work:=_plain(box,_short_work(String(leaders.get("work",""))),14,T.BODY);work.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
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
		var spec:Array=allure_parts().get(String(p.source),[String(p.source),T.MUTED])
		ribbon.parts.append([float(p.value),spec[1]])
		var item:=HBoxContainer.new();item.add_theme_constant_override("separation",5);item.mouse_filter=Control.MOUSE_FILTER_STOP;item.tooltip_text=String(p.text)
		var swatch:=ColorRect.new();swatch.color=spec[1];swatch.custom_minimum_size=Vector2(10,10);swatch.size_flags_vertical=Control.SIZE_SHRINK_CENTER;swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE;item.add_child(swatch)
		_plain(item,"%s +%d" % [String(spec[0]),roundi(float(p.value)*100.0)],12,T.INK)
		legend.add_child(item)
	# What allure brings: three figures.
	var tiles:=HFlowContainer.new();tiles.add_theme_constant_override("h_separation",24);tiles.add_theme_constant_override("v_separation",8);box.add_child(tiles)
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
	var tile:=HBoxContainer.new();tile.add_theme_constant_override("separation",8);tile.tooltip_text=tip;tile.mouse_filter=Control.MOUSE_FILTER_STOP;parent.add_child(tile)
	_plain(tile,label,14,T.MUTED)
	_plain(tile,figure,20,T.RED_TEXT if warn else T.INK)

func _serif(value:String,font_size:int)->Label:
	var label:=T.make_label(value,font_size,T.INK);label.add_theme_font_override("font",T.font("ui_strong"));label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(parent:Node,label:String,callback:Variant,tip:String,active:bool=false)->Button:
	return T.apply_button_style(super._button(parent,label,callback,tip,active))
