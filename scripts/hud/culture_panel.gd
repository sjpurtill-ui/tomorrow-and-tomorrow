extends "res://scripts/hud/settlement_overview.gd"
## THE CULTURE SCREEN: what our ways DO, in the engine's numbers
## (hud/culture_model.gd). Top to bottom, by how much each weighs in play:
##   who we are (the name our values make of us, our people's temper);
##   what our ways do to the realm (the ledger: every lever our course and our
##     values move now, as one diverging bar each, with its two sources);
##   the course we follow (this century's and the remembered ones, by share,
##     with their gains and costs and the research they lean);
##   what we live by (all ten values: where the people live and what is
##     upheld over them, and the gap between, which costs cohesion);
##   how our leaders behave (the people's temper and the work it leans);
##   how others see our ways (allure, its parts and what it does; what
##     newcomers not yet settled cost; the collection).
## The daily refresh keeps the page while its rounded figures hold.
const Visuals:=preload("res://scripts/hud/research_visuals.gd")
const CultureModelRef:=preload("res://scripts/hud/culture_model.gd")

## A bar either side of a middle line: gains to the right, costs to the left.
class Diverging extends Control:
	var value:=0.0
	var span:=0.10
	func _init()->void:
		custom_minimum_size=Vector2(140,10)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		var mid:=size.x*0.5
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		var w:=clampf(absf(value)/maxf(0.001,span),0.0,1.0)*mid
		if value>=0.0: draw_rect(Rect2(Vector2(mid,0),Vector2(w,size.y)),T.GREEN)
		else: draw_rect(Rect2(Vector2(mid-w,0),Vector2(w,size.y)),T.RED)
		draw_line(Vector2(mid,-2),Vector2(mid,size.y+2),T.INK,1.0)

## A value's line: where the people live (a filled mark) and what is upheld
## (a ring), with the gap between shaded.
class Spectrum extends Control:
	var lived:=0.5
	var official:=0.5
	func _init()->void:
		custom_minimum_size=Vector2(120,14)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		var y:=size.y*0.5
		draw_line(Vector2(0,y),Vector2(size.x,y),T.TRACK,3.0)
		var a:=lived*size.x
		var b:=official*size.x
		if absf(a-b)>2.0: draw_line(Vector2(minf(a,b),y),Vector2(maxf(a,b),y),Color(T.RED,0.55),4.0)
		draw_arc(Vector2(b,y),5.0,0.0,TAU,20,T.INK,1.5,true)
		draw_circle(Vector2(a,y),4.2,T.GOLD)

## A thin meter (0..1).
class Meter extends Control:
	var value:=0.0
	func _init()->void:
		custom_minimum_size=Vector2(110,7)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*clampf(value,0.0,1.0),size.y)),T.GOLD)

var _print:Array=[]
var _columns:Array[GridContainer]=[]

func setup(block:Dictionary)->void:
	data=block;name="CulturePanel";add_theme_constant_override("separation",18)
	_print=page_print(block)
	_build()
	resized.connect(_layout)

## The live refresh: the page stays while its rounded figures hold; a figure
## that moved draws the page again (rarely: values drift over years).
func update_block(block:Dictionary)->bool:
	var next:=page_print(block)
	data=block
	if next==_print: return true
	_print=next
	for child in get_children(): remove_child(child);child.queue_free()
	_columns.clear()
	_build()
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
		roundi(float((c.get("alignment",{}) as Dictionary).get("alignment",0.0))*100.0),_showcase_print(block),Portrait.Early.active()]

static func _showcase_print(block:Dictionary)->Array:
	var artifacts:Dictionary=block.get("artifacts",{})
	return [artifacts.get("summary",{}),artifacts.get("highlights",[])]

func _build()->void:
	var c:Dictionary=data.get("culture",{})
	_who(c)
	_rule(self)
	_ledger(c)
	_rule(self)
	_course(c)
	_rule(self)
	_values(c)
	_rule(self)
	_leaders(c)
	_rule(self)
	_others(c)
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",10);add_child(actions)
	if data.get("on_council") is Callable: _button(actions,"Talk with our leader in court",data.on_council,"Call the local leader to the court")
	if data.get("on_capacities") is Callable: _button(actions,"What we are good and poor at",data.on_capacities,"Twelve things a people needs, weakest first")
	_layout()

func _layout()->void:
	var columns:=2 if size.x>=600 else 1
	for grid in _columns:
		if is_instance_valid(grid): grid.columns=columns

func _kicker(parent:Node,text:String)->void:
	parent.add_child(T.make_label(text,12,T.GOLD_TEXT))

func _grid(parent:Node)->GridContainer:
	var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",22);grid.add_theme_constant_override("v_separation",12)
	parent.add_child(grid);_columns.append(grid)
	return grid

func _plain(text:String,size:int,color:Color)->Label:
	var label:=T.make_label(text,size,color)
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	return label

# --- Who we are ------------------------------------------------------------------

func _who(c:Dictionary)->void:
	var identity:Dictionary=c.get("identity",{})
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",22);add_child(row)
	var image:=TextureRect.new();image.texture=Visuals.art("culture");image.custom_minimum_size=Vector2(200,160)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if Portrait.Early.active():
		image.texture=Portrait.Early.civic_scene(data.get("lived_values",{}))
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.tooltip_text="A picture of how the people live now."
	row.add_child(image)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",8);row.add_child(words)
	_kicker(words,"WHO WE ARE")
	words.add_child(_serif(String(identity.get("name","")).capitalize(),26))
	_line(words,"Most of all: %s." % String(identity.get("summary","")).to_lower(),13,T.BODY)
	var leaders:Dictionary=c.get("leaders",{})
	_line(words,"Our people's temper, which our leaders follow: %s." % String(leaders.get("temperament","")).to_lower(),13,T.BODY)
	_note(words,"Our culture is the course we follow and the values we live by. Both work on the realm every day, as below.")

# --- What our ways do --------------------------------------------------------------

func _ledger(c:Dictionary)->void:
	_kicker(self,"WHAT OUR WAYS DO TO THE REALM")
	_note(self,"Every lever our course and our values move now, against what it would be without them. Green helps, red costs.")
	var rows:Array=c.get("ledger",[])
	if rows.is_empty():
		_note(self,"Our ways move nothing yet: no course chosen, and our values still near the middle.");return
	var span:=0.05
	for r:Dictionary in rows: span=maxf(span,absf(float(r.total)))
	var table:=GridContainer.new();table.name="Ledger";table.columns=4;table.add_theme_constant_override("h_separation",14);table.add_theme_constant_override("v_separation",8);add_child(table)
	for r:Dictionary in rows:
		var label:=_plain(String(r.label),14,T.INK);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;table.add_child(label)
		var bar:=Diverging.new();bar.value=float(r.total);bar.span=span;table.add_child(bar)
		var total:=_plain(CultureModelRef.pct(float(r.total)),14,T.GREEN_TEXT if float(r.total)>=0.0 else T.RED_TEXT);total.custom_minimum_size.x=56;total.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;table.add_child(total)
		var parts:PackedStringArray=[]
		if absf(float(r.course))>=0.004: parts.append("course %s" % CultureModelRef.pct(float(r.course)))
		if absf(float(r.values))>=0.004: parts.append("values %s" % CultureModelRef.pct(float(r.values)))
		table.add_child(_plain(" · ".join(parts),12,T.MUTED))

# --- The course ----------------------------------------------------------------------

func _course(c:Dictionary)->void:
	var course:Dictionary=c.get("course",{})
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",18);add_child(head)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",6);head.add_child(words)
	_kicker(words,"THE COURSE WE FOLLOW")
	words.add_child(_serif(String(course.get("name","")),23))
	if String(course.get("vision",""))!="": _line(words,String(course.vision),13,T.BODY)
	if data.get("on_direction") is Callable:
		_button(head,"Review the course",data.on_direction,"The century's course: chosen again at each century's turn")
		(head.get_child(head.get_child_count()-1) as Control).size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var remembered:Array=course.get("remembered",[])
	if remembered.is_empty(): return
	_note(self,"A course works by its share of the people's memory: this century's counts most, and older courses fade by half every sixty years.")
	var grid:=_grid(self)
	for r:Dictionary in remembered.slice(0,4):
		var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_constant_override("separation",4);grid.add_child(card)
		var top:=HBoxContainer.new();top.add_theme_constant_override("separation",8);card.add_child(top)
		var name:=_plain(String(r.name)+(" (now)" if bool(r.current) else ""),15,T.INK);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(name)
		top.add_child(_plain("%d in 100 of our memory" % roundi(float(r.share)*100.0),12,T.MUTED))
		var meter:=Meter.new();meter.value=float(r.share);card.add_child(meter)
		_line(card,"At full strength: %s" % String(r.does),12,T.BODY)
	var research:Array=course.get("research",[])
	if not research.is_empty():
		# The fields our course favours by name; the rest, slowed alike, in one word.
		var favoured:PackedStringArray=[]
		var slowed:=-1.0
		for r:Dictionary in research:
			if float(r.multiplier)>1.0: favoured.append("%s ×%.2f" % [Visuals.name_for(String(r.domain)),float(r.multiplier)])
			else: slowed=float(r.multiplier) if slowed<0.0 else minf(slowed,float(r.multiplier))
		var said:="Research our course leans: %s" % ", ".join(favoured) if not favoured.is_empty() else "Research our course leans"
		if slowed>0.0: said+="%severy other field ×%.2f" % ["; " if not favoured.is_empty() else ": ",slowed]
		_line(self,said+".",13,T.BODY)

# --- The values -------------------------------------------------------------------

func _values(c:Dictionary)->void:
	_kicker(self,"WHAT WE LIVE BY")
	var a:Dictionary=c.get("alignment",{})
	var agree:=roundi(float(a.get("alignment",0.0))*100.0)
	var say:="What our people live by and what is upheld over them agree %d in 100. That moves how close they hold %s and their trust in those who rule %s." % [agree,CultureModelRef.pct(float(a.get("cohesion",0.0))),CultureModelRef.pct(float(a.get("legitimacy",0.0)))]
	var widest:Dictionary=a.get("widest",{})
	if not widest.is_empty() and float(widest.get("gap",0.0))>=0.12:
		say+=" The widest gap is %s: the people live nearer %s than what is upheld." % [String(widest.name).to_lower(),(String(widest.high) if float(widest.lived)>float(widest.official) else String(widest.low)).to_lower()]
	_line(self,say,13,T.BODY)
	_note(self,"Gold mark: where the people live. Ring: what is upheld. A red stretch between is a gap that costs cohesion.")
	var grid:=_grid(self)
	for v:Dictionary in c.get("values",[]):
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",3);grid.add_child(cell)
		cell.tooltip_text=String(v.meaning)
		cell.add_child(_plain(String(v.name).to_upper(),12,T.GOLD_TEXT))
		var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);cell.add_child(line)
		var lo:=_plain(String(v.low),12,T.MUTED);lo.custom_minimum_size.x=96;line.add_child(lo)
		var bar:=Spectrum.new();bar.lived=float(v.lived);bar.official=float(v.official);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(bar)
		var hi:=_plain(String(v.high),12,T.MUTED);hi.custom_minimum_size.x=96;hi.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;line.add_child(hi)

# --- Our leaders -----------------------------------------------------------------

func _leaders(c:Dictionary)->void:
	var leaders:Dictionary=c.get("leaders",{})
	_kicker(self,"HOW OUR LEADERS BEHAVE")
	_note(self,"Where you do not decide, our leaders act by the people's temper, read from the values they live by: the daily work, what is studied, and how fast we grow.")
	var grid:=_grid(self)
	for s:Dictionary in leaders.get("sides",[]):
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",3);grid.add_child(cell)
		var top:=HBoxContainer.new();cell.add_child(top)
		var n:=_plain(String(s.name),14,T.INK);n.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(n)
		top.add_child(_plain("%d" % roundi(float(s.value)*100.0),13,T.MUTED))
		var meter:=Meter.new();meter.value=float(s.value);cell.add_child(meter)
		_line(cell,"The more, the more they %s." % String(s.means),12,T.BODY)
	var work:=_line(self,String(leaders.get("work","")),13,T.BODY)
	work.tooltip_text=String(leaders.get("work_tip",""))

# --- Others ------------------------------------------------------------------------

func _others(c:Dictionary)->void:
	var o:Dictionary=c.get("others",{})
	_kicker(self,"HOW OTHERS SEE OUR WAYS")
	_line(self,"Allure %d in 100 (%s): how much other peoples want to come to us, trade with us and learn from us." % [roundi(float(o.get("allure",0.0))*100.0),String(o.get("label","")).to_lower()],13,T.BODY)
	var grid:=_grid(self)
	for p:Dictionary in o.get("parts",[]):
		var cell:=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_constant_override("separation",3);grid.add_child(cell)
		var top:=HBoxContainer.new();cell.add_child(top)
		var n:=_plain(String({"collection":"Our collection","culture":"Our shared ways","values":"Open, plural values","works":"Great works"}.get(String(p.source),String(p.source).capitalize())),14,T.INK);n.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(n)
		top.add_child(_plain("+%d" % roundi(float(p.value)*100.0),13,T.MUTED))
		_line(cell,String(p.text),12,T.BODY)
	for e:Dictionary in o.get("effects",[]): _line(self,"• "+String(e.text),13,T.BODY)
	if float(o.get("unsettled",0.0))>=1.0:
		_line(self,"%d newcomers are not yet settled among us: until they are, they cost %s of how close our people hold." % [roundi(float(o.unsettled)),CultureModelRef.pct(-float(o.get("integration_cost",0.0)))],13,T.RED_TEXT)
	if data.has("artifacts"):
		add_child(preload("res://scripts/hud/artifact_gallery.gd").showcase(data.artifacts))
