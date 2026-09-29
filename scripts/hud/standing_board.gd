extends VBoxContainer
## THE STANDING BOARD: the heart of the game on one page.
##
##   ┌ what we are: our seal, the words the shape of our strengths makes of us,
##   │ the rose of nine strengths (last year's shape faint behind it, and any
##   │ people we know laid over it) beside the nine, each with its reason,
##   │ its change in a year and the place that raises it
##   ├ dangers: what the peoples we know will do about what they see, with the
##   │ engine's own odds, and what answers each
##   ├ how each people we know sees us: six feelings, what they make them do,
##   │ what they remember, and a word with them in the court
##   └ our own people: pride, love and dread of the god, trust in the chiefs
##
## Data: content/dock_content_standing.gd. The live refresh updates this
## widget in place (update_block), so the page never jumps under the reader.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Standing:=preload("res://scripts/standing.gd")

const WIDE_AT:=620.0
const TWO_CARDS_AT:=700.0

## A thin ink bar.
class Meter extends Control:
	var fill:=0.0
	var color:=Color.WHITE
	func _init()->void:
		custom_minimum_size=Vector2(40,6)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_vertical=Control.SIZE_SHRINK_CENTER
	func set_value(value:float,tint:Color)->void:
		fill=clampf(value,0.0,1.0);color=tint;queue_redraw()
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.PAPER_SUNK)
		draw_rect(Rect2(Vector2.ZERO,size),T.RULE,false,1.0)
		if fill>0.0: draw_rect(Rect2(Vector2.ZERO,Vector2(maxf(2.0,size.x*fill),size.y)),color)

## A round gauge with its value in the middle.
class Medallion extends Control:
	var value:=0.0
	var color:=Color.WHITE
	func _init()->void:
		custom_minimum_size=Vector2(76,76)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	func set_value(amount:float,tint:Color)->void:
		value=clampf(amount,0.0,1.0);color=tint;queue_redraw()
	func _draw()->void:
		var center:=size*0.5
		var radius:=minf(size.x,size.y)*0.5-5.0
		draw_circle(center,radius+3.0,T.PAPER_RAISED)
		draw_arc(center,radius,0.0,TAU,64,T.PAPER_SUNK,6.0,true)
		if value>0.0: draw_arc(center,radius,-PI*0.5,-PI*0.5+TAU*value,64,color,6.0,true)
		draw_arc(center,radius+3.5,0.0,TAU,64,T.RULE,1.0,true)
		var text:="%d%%" % roundi(value*100.0)
		var font:=T.font("ui_strong")
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
		draw_string(font,center+Vector2(-width*0.5,7.0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,T.INK)

## The rose of our nine strengths, drawn like a chart's wind rose.
class Rose extends Control:
	signal picked(id:String)
	var strengths:Array=[]
	var ghost:Dictionary={}
	var theirs:Dictionary={}
	var their_color:=Color.WHITE
	var their_name:=""
	var highlight:=-1
	func _init()->void:
		custom_minimum_size=Vector2(330,330)
		mouse_filter=Control.MOUSE_FILTER_STOP
		size_flags_horizontal=Control.SIZE_EXPAND_FILL
		mouse_exited.connect(func()->void: set_highlight(-1))
	func configure(items:Array,year_ago:Dictionary)->void:
		strengths=items;ghost=year_ago;queue_redraw()
	func compare(values:Dictionary,tint:Color,name:String)->void:
		theirs=values;their_color=tint;their_name=name;queue_redraw()
	func set_highlight(index:int)->void:
		if index==highlight: return
		highlight=index;queue_redraw()
	func _center()->Vector2:
		return size*0.5
	func _radius()->float:
		return maxf(40.0,minf(size.x,size.y)*0.5-58.0)
	func _angle(index:int)->float:
		return -PI*0.5+TAU*float(index)/float(maxi(1,strengths.size()))
	func _point(index:int,amount:float)->Vector2:
		return _center()+Vector2.from_angle(_angle(index))*_radius()*clampf(amount,0.0,1.0)
	func _draw()->void:
		var count:=strengths.size()
		if count<3: return
		var center:=_center()
		var radius:=_radius()
		# The chart: four rings and nine spokes, in the rule's ink.
		draw_circle(center,radius+10.0,Color(T.PAPER_RAISED,0.9))
		for ring in [0.25,0.5,0.75,1.0]:
			var outline:=PackedVector2Array()
			for i in count+1: outline.append(center+Vector2.from_angle(_angle(i%count))*radius*ring)
			draw_polyline(outline,T.RULE_STRONG if ring==1.0 else T.RULE,1.4 if ring==1.0 else 1.0,true)
		for i in count:
			draw_line(center,center+Vector2.from_angle(_angle(i))*radius,T.RULE_STRONG if i==highlight else T.RULE,2.0 if i==highlight else 1.0,true)
		# Last year's shape, faint, so the change shows.
		if not ghost.is_empty():
			var past:=PackedVector2Array()
			for i in count: past.append(_point(i,float(ghost.get(String(strengths[i].id),0.0))/100.0))
			past.append(past[0])
			for i in past.size()-1: _dashes(past[i],past[i+1],T.INK_MUTED,1.2,4.0)
		# A people we know, laid over ours.
		if not theirs.is_empty():
			var shape:=PackedVector2Array()
			for i in count: shape.append(_point(i,maxf(0.02,float((theirs.get(String(strengths[i].id),{}) as Dictionary).get("value",0.0)))))
			if shape.size()>=3: draw_colored_polygon(shape,Color(their_color,0.10))
			shape.append(shape[0])
			for i in shape.size()-1: _dashes(shape[i],shape[i+1],their_color.darkened(0.15),2.2,7.0)
		# Ours: a gold wash and a gold line.
		var ours:=PackedVector2Array()
		for i in count: ours.append(_point(i,maxf(0.02,float(strengths[i].value))))
		draw_colored_polygon(ours,Color(T.GOLD,0.20))
		var line:=ours.duplicate();line.append(ours[0])
		draw_polyline(line,T.GOLD,2.6,true)
		for i in count:
			draw_circle(ours[i],5.0 if i==highlight else 3.6,T.GOLD)
			draw_circle(ours[i],1.8,T.PAPER_RAISED)
		# The names round the rim, with the value under each.
		var strong:=T.font("ui_strong")
		var plain:=T.FONT_UI
		for i in count:
			var item:Dictionary=strengths[i]
			var direction:=Vector2.from_angle(_angle(i))
			var anchor:=center+direction*(radius+16.0)
			var name:=String(item.name)
			var value:="%d%%" % roundi(float(item.value)*100.0)
			var name_size:=strong.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
			var value_size:=plain.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,13)
			var block_width:=maxf(name_size.x,value_size.x)
			var x:=anchor.x-block_width*0.5
			if direction.x>0.35: x=anchor.x
			elif direction.x<-0.35: x=anchor.x-block_width
			var y:=anchor.y-2.0
			if direction.y<-0.6: y=anchor.y-18.0
			elif direction.y>0.6: y=anchor.y+10.0
			draw_string(strong,Vector2(x+(block_width-name_size.x)*(0.0 if direction.x>0.35 else 1.0 if direction.x<-0.35 else 0.5),y),name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,T.GOLD_TEXT if i==highlight else T.INK)
			draw_string(plain,Vector2(x+(block_width-value_size.x)*(0.0 if direction.x>0.35 else 1.0 if direction.x<-0.35 else 0.5),y+15.0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK_MUTED)
		if their_name!="" and not theirs.is_empty():
			var note:="- - %s, as travellers tell it" % their_name
			draw_string(plain,Vector2(8.0,size.y-8.0),note,HORIZONTAL_ALIGNMENT_LEFT,size.x-16.0,12,T.text_for(their_color) if their_color!=Color.WHITE else T.INK_MUTED)
	func _dashes(from:Vector2,to:Vector2,color:Color,width:float,dash:float)->void:
		var length:=from.distance_to(to)
		if length<0.5: return
		var step:=dash*2.0
		var along:=0.0
		while along<length:
			var start:=from.lerp(to,along/length)
			var end:=from.lerp(to,minf(length,along+dash)/length)
			draw_line(start,end,color,width,true)
			along+=step
	func _index_at(at:Vector2)->int:
		var offset:=at-_center()
		if offset.length()<12.0 or offset.length()>_radius()+60.0: return -1
		var count:=strengths.size()
		var best:=-1
		var best_gap:=INF
		for i in count:
			var gap:=absf(angle_difference(offset.angle(),_angle(i)))
			if gap<best_gap: best_gap=gap;best=i
		return best
	func _gui_input(event:InputEvent)->void:
		if event is InputEventMouseMotion: set_highlight(_index_at((event as InputEventMouseMotion).position))
		elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
			var index:=_index_at((event as InputEventMouseButton).position)
			if index>=0: picked.emit(String(strengths[index].id))
	func _get_tooltip(at_position:Vector2)->String:
		var index:=_index_at(at_position)
		if index<0: return ""
		var item:Dictionary=strengths[index]
		var text:="%s %d%%: %s.\n%s." % [String(item.name),roundi(float(item.value)*100.0),String(item.means),String(item.why).left(1).to_upper()+String(item.why).substr(1)]
		if not theirs.is_empty(): text+="\n%s: about %d%%." % [their_name,roundi(float((theirs.get(String(item.id),{}) as Dictionary).get("value",0.0))*100.0)]
		return text+"\nClick to open %s." % String(item.section_name)

var data:Dictionary={}
var prints:Dictionary={}
var rose:Rose
var seal:TextureRect
var name_label:Label
var posture_label:Label
var renown_label:Label
var hero_body:GridContainer
var strength_list:VBoxContainer
var strength_rows:Array[Control]=[]
var compare_row:HFlowContainer
var dangers:VBoxContainer
var peoples_heading:Label
var peoples:GridContainer
var home:VBoxContainer

func setup(block:Dictionary)->void:
	name="StandingBoard"
	add_theme_constant_override("separation",18)
	_build_hero()
	dangers=VBoxContainer.new();dangers.name="Dangers";dangers.add_theme_constant_override("separation",8);add_child(dangers)
	var peoples_box:=VBoxContainer.new();peoples_box.name="Peoples";peoples_box.add_theme_constant_override("separation",10);add_child(peoples_box)
	peoples_heading=Kit.label(peoples_box,"How the peoples we know see us","kicker")
	peoples=GridContainer.new();peoples.name="PeopleCards";peoples.columns=2
	peoples.add_theme_constant_override("h_separation",14);peoples.add_theme_constant_override("v_separation",14)
	peoples_box.add_child(peoples)
	home=VBoxContainer.new();home.name="Home";home.add_theme_constant_override("separation",10);add_child(home)
	resized.connect(_layout)
	apply(block)
	_layout()

## The live refresh: same widget, new data.
func update_block(block:Dictionary)->bool:
	apply(block)
	return true

func apply(block:Dictionary)->void:
	data=block
	name_label.text=String(block.get("people_name","Our people"))
	posture_label.text=String((block.get("posture",{}) as Dictionary).get("words",""))
	var renown:Dictionary=block.get("renown",{})
	renown_label.text="Our name commands awe %d%% and allure %d%%." % [roundi(float(renown.get("awe",0.0))*100.0),roundi(float(renown.get("allure",0.0))*100.0)] if not renown.is_empty() else ""
	seal.texture=Identity.emblem("player")
	_refill("strengths",[block.get("strengths",[]),block.get("year_ago",{})],_fill_strengths)
	_refill("compare",[_compare_print(),String((block.get("view_state",{}) as Dictionary).get("compare",""))],_fill_compare)
	_refill("dangers",block.get("warnings",[]),_fill_dangers)
	_refill("peoples",block.get("peoples",[]),_fill_peoples)
	_refill("home",block.get("home",{}),_fill_home)

func _refill(part:String,value:Variant,fill:Callable)->void:
	var print:=preload("res://scripts/hud/dock_panel.gd").fingerprint(value)
	if String(prints.get(part,""))==print: return
	prints[part]=print
	fill.call()

func _compare_print()->Array:
	var out:Array=[]
	for p:Dictionary in data.get("peoples",[]): out.append([String(p.civ_id),(p.get("theirs",{}) as Dictionary).is_empty()])
	return out

func _layout()->void:
	if hero_body: hero_body.columns=2 if size.x>=WIDE_AT else 1
	if peoples: peoples.columns=2 if size.x>=TWO_CARDS_AT else 1

static func _card(accent:Color=Color(0,0,0,0),pad:float=16.0)->PanelContainer:
	var card:=PanelContainer.new()
	var style:=T.paper_panel_style(true,T.RADIUS_CARD,pad)
	if accent.a>0.0:
		style.border_color=accent
		style.border_width_top=3
	card.add_theme_stylebox_override("panel",style)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return card

static func _voice(parent:Node,text:String,size:int=20,italic:bool=true,color:Color=Color(0,0,0,0))->Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_override("font",T.voice_font(italic))
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color if color.a>0.0 else T.INK)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

static func _clear(node:Node)->void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

static func _tone_color(tone:String)->Color:
	match tone:
		"danger": return T.RED
		"warning": return T.AMBER
		"good": return T.TEAL
	return T.INK_MUTED

# ----------------------------------------------------------------- the hero

func _build_hero()->void:
	var card:=_card(T.GOLD,20.0)
	card.name="WhatWeAre"
	add_child(card)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);card.add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",16);column.add_child(top)
	seal=TextureRect.new();seal.name="Seal"
	seal.custom_minimum_size=Vector2(76,76)
	seal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	top.add_child(seal)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",4);top.add_child(words)
	Kit.label(words,"What we are","kicker")
	name_label=Label.new();name_label.name="PeopleName"
	T.text(name_label,"title",T.INK)
	name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	words.add_child(name_label)
	posture_label=_voice(words,"",21)
	posture_label.name="Posture"
	renown_label=Kit.label(words,"","note")
	renown_label.name="Renown"
	renown_label.tooltip_text="What our name commands by what we are: awe from might, great works and a lead in learning; allure from our culture, plenty, learning and good order. Both make our own people proud; allure draws others to us, awe makes them wary."
	hero_body=GridContainer.new();hero_body.name="Strengths";hero_body.columns=2
	hero_body.add_theme_constant_override("h_separation",18);hero_body.add_theme_constant_override("v_separation",12)
	column.add_child(hero_body)
	rose=Rose.new();rose.name="Rose"
	rose.picked.connect(_raise)
	hero_body.add_child(rose)
	strength_list=VBoxContainer.new();strength_list.name="StrengthList"
	strength_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	strength_list.add_theme_constant_override("separation",4)
	hero_body.add_child(strength_list)
	compare_row=HFlowContainer.new();compare_row.name="Compare"
	compare_row.add_theme_constant_override("h_separation",8);compare_row.add_theme_constant_override("v_separation",6)
	column.add_child(compare_row)

func _fill_strengths()->void:
	var items:Array=data.get("strengths",[])
	rose.configure(items,data.get("year_ago",{}))
	_clear(strength_list)
	strength_rows.clear()
	Kit.label(strength_list,"Faint dashes on the rose: a year ago. Click a strength to raise it." if not (data.get("year_ago",{}) as Dictionary).is_empty() else "Click a strength to raise it.","note")
	for index in items.size():
		strength_list.add_child(_strength_row(items[index],index))

func _strength_row(item:Dictionary,index:int)->Control:
	var row:=PanelContainer.new()
	row.name="Strength_"+String(item.id)
	row.mouse_filter=Control.MOUSE_FILTER_STOP
	row.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	var calm:=T.flat(Color(0,0,0,0),Color(0,0,0,0),0,T.RADIUS_CONTROL,6.0)
	var lit:=T.flat(T.GOLD_WASH,T.RULE,1,T.RADIUS_CONTROL,6.0)
	row.add_theme_stylebox_override("panel",calm)
	row.tooltip_text="%s: %s.\n%s.\nRaised through %s; it costs %s. Click to open %s." % [String(item.name),String(item.means),String(item.why),String(item.section_name),String(item.cost),String(item.section_name)]
	row.mouse_entered.connect(func()->void: row.add_theme_stylebox_override("panel",lit);rose.set_highlight(index))
	row.mouse_exited.connect(func()->void: row.add_theme_stylebox_override("panel",calm);rose.set_highlight(-1))
	row.gui_input.connect(func(event:InputEvent)->void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT: _raise(String(item.id)))
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",3);column.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(column)
	var head:=HBoxContainer.new();head.add_theme_constant_override("separation",8);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(head)
	var name:=Kit.label(head,String(item.name),"heading",Color(0,0,0,0),false);name.mouse_filter=Control.MOUSE_FILTER_IGNORE
	name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if item.has("change"):
		var change:=float(item.change)
		var words:="steady over the year" if absf(change)<1.0 else ("%s%d in a year" % ["+" if change>0.0 else "−",roundi(absf(change))])
		var tint:=T.MUTED if absf(change)<1.0 else (T.GREEN_TEXT if change>0.0 else T.RED_TEXT)
		var moved:=T.make_label(words,12,tint);moved.mouse_filter=Control.MOUSE_FILTER_IGNORE;moved.size_flags_vertical=Control.SIZE_SHRINK_CENTER;head.add_child(moved)
	var value:=Kit.label(head,"%d%%" % roundi(float(item.value)*100.0),"value",Color(0,0,0,0),false);value.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var meter:=Meter.new();meter.set_value(float(item.value),T.GOLD);column.add_child(meter)
	var why:=Kit.label(column,_sentence(String(item.why)),"note");why.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return row

func _raise(id:String)->void:
	var raise:Variant=data.get("on_raise")
	if not raise is Callable or not (raise as Callable).is_valid(): return
	for item:Dictionary in data.get("strengths",[]):
		if String(item.id)==id:
			(raise as Callable).call(String(item.section),int(item.sub))
			return

func _fill_compare()->void:
	_clear(compare_row)
	var list:Array=data.get("peoples",[])
	var state:Dictionary=data.get("view_state",{})
	var chosen:=String(state.get("compare",""))
	var shown:=false
	if list.is_empty():
		rose.compare({},Color.WHITE,"")
		return
	var caption:=Kit.label(compare_row,"Lay beside ours:","note",Color(0,0,0,0),false)
	caption.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	for p:Dictionary in list:
		var theirs:Dictionary=p.get("theirs",{})
		var chip:=Button.new()
		chip.name="Compare_"+String(p.civ_id)
		chip.toggle_mode=true
		chip.text=String(p.name)
		chip.disabled=theirs.is_empty()
		chip.tooltip_text="We know too little of them yet." if theirs.is_empty() else "Lay %s's strengths, as travellers tell it, over ours." % String(p.name)
		chip.button_pressed=String(p.civ_id)==chosen
		chip.add_theme_font_size_override("font_size",13)
		chip.add_theme_color_override("font_color",T.INK)
		chip.add_theme_color_override("font_pressed_color",T.INK)
		chip.add_theme_color_override("font_hover_color",T.INK)
		chip.add_theme_stylebox_override("normal",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CONTROL,6.0))
		chip.add_theme_stylebox_override("hover",T.flat(T.HOVER_BG,T.RULE,1,T.RADIUS_CONTROL,6.0))
		chip.add_theme_stylebox_override("pressed",T.flat(T.GOLD_WASH,T.GOLD,1,T.RADIUS_CONTROL,6.0))
		chip.add_theme_stylebox_override("disabled",T.flat(T.PAPER_SUNK,T.RULE,1,T.RADIUS_CONTROL,6.0))
		var civ_id:=String(p.civ_id)
		chip.pressed.connect(func()->void:
			state["compare"]="" if String(state.get("compare",""))==civ_id else civ_id
			prints.erase("compare")
			_fill_compare())
		compare_row.add_child(chip)
		if String(p.civ_id)==chosen and not theirs.is_empty():
			var tint:Color=p.get("accent",T.RED)
			rose.compare(theirs,tint,String(p.name))
			shown=true
	if not shown: rose.compare({},Color.WHITE,"")

# -------------------------------------------------------------- the dangers

func _fill_dangers()->void:
	_clear(dangers)
	var warnings:Array=data.get("warnings",[])
	dangers.visible=true
	Kit.label(dangers,"What they will do about it","kicker")
	if warnings.is_empty():
		var calm:=_card(T.TEAL)
		dangers.add_child(calm)
		var text:="No people we know is moved against us by what it sees." if not (data.get("peoples",[]) as Array).is_empty() else "No people knows us yet, so none can envy us or think us weak."
		Kit.label(calm,text,"body")
		return
	for warning:Dictionary in warnings.slice(0,5):
		var card:=_card(_tone_color(String(warning.tone)),12.0)
		dangers.add_child(card)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
		var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",2);row.add_child(words)
		Kit.label(words,String(warning.title),"heading",_tone_color(String(warning.tone)))
		Kit.label(words,String(warning.words),"body")
		var raise:Variant=data.get("on_raise")
		if String(warning.get("section",""))!="" and raise is Callable:
			var section:=String(warning.section)
			var sub:=int(warning.get("sub",0))
			var button:=Kit.button(row,String(warning.get("action","Open")),false,func()->void: (raise as Callable).call(section,sub),"Open %s" % String(warning.get("action","")))
			button.size_flags_vertical=Control.SIZE_SHRINK_CENTER

# -------------------------------------------------------------- the peoples

func _fill_peoples()->void:
	_clear(peoples)
	var list:Array=data.get("peoples",[])
	if list.is_empty():
		var card:=_card()
		card.name="NoPeoples"
		peoples.add_child(card)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);card.add_child(column)
		_voice(column,"No other people has met us yet.",20,false)
		Kit.label(column,"When our scouts or theirs cross paths, each people will come to see us in its own way: drawn to us, in awe, afraid, respectful, trusting or resentful, by what we are and by what we do to them.","body")
		var scouts:Variant=data.get("on_scouts")
		if scouts is Callable: Kit.button(column,"Send scouts",true,scouts as Callable,"Send scouts to find the peoples around us")
		return
	for p:Dictionary in list: peoples.add_child(_people_card(p))

func _people_card(p:Dictionary)->Control:
	var accent:Color=p.get("accent",T.GOLD)
	var card:=_card(accent)
	card.name="People_"+String(p.civ_id)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);card.add_child(column)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",12);column.add_child(top)
	var emblem:=TextureRect.new()
	emblem.texture=p.get("emblem") as Texture2D
	emblem.custom_minimum_size=Vector2(48,48)
	emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	top.add_child(emblem)
	var title:=VBoxContainer.new();title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_constant_override("separation",1);top.add_child(title)
	_voice(title,String(p.name),22,false)
	Kit.label(title,String(p.relation),"note")
	if String(p.get("ruler",""))!="": Kit.label(title,String(p.ruler),"note")
	_voice(column,String(p.headline),18)
	var grid:=GridContainer.new();grid.columns=2
	grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",6)
	column.add_child(grid)
	for view:Dictionary in p.get("views",[]):
		grid.add_child(_feeling(view))
	var strength:=Kit.label(column,String(p.strength)+".","body")
	strength.tooltip_text="Fighting strength: everyone who can defend the homes, and warriors trained and ready counted three times over."
	strength.mouse_filter=Control.MOUSE_FILTER_PASS
	for pair:Array in [["envy","Envy",Standing.ENVY_RAID_FLOOR],["contempt","Contempt",Standing.CONTEMPT_FLOOR]]:
		var amount:=float(p.get(String(pair[0]),0.0))
		if amount<=float(pair[2]): continue
		var danger:=HBoxContainer.new();danger.add_theme_constant_override("separation",8);column.add_child(danger)
		var badge:=T.make_label("%s %d%%" % [String(pair[1]),roundi(amount*100.0)],12,T.RED_TEXT)
		badge.add_theme_stylebox_override("normal",T.flat(T.DANGER_BG,T.DANGER_BORDER,1,T.RADIUS_CONTROL,4.0))
		danger.add_child(badge)
		var why:=Kit.label(danger,String(p.get(String(pair[0])+"_why","")),"note")
		why.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var doings:Array=p.get("consequences",[])
	if not doings.is_empty():
		Kit.label(column,"What it makes them do","kicker")
		for c:Dictionary in doings:
			var line:=HBoxContainer.new();line.add_theme_constant_override("separation",8);column.add_child(line)
			var dot:=ColorRect.new();dot.custom_minimum_size=Vector2(8,8);dot.color=_tone_color(String(c.tone));dot.size_flags_vertical=Control.SIZE_SHRINK_CENTER;line.add_child(dot)
			var words:=Kit.label(line,String(c.words),"body")
			words.tooltip_text=String(c.get("detail",""))
			words.mouse_filter=Control.MOUSE_FILTER_PASS
	var memories:Array=p.get("memories",[])
	if not memories.is_empty():
		Kit.label(column,"What they remember","kicker")
		for memory:Dictionary in memories:
			Kit.label(column,String(memory.text),"note",_tone_color(String(memory.tone)))
	var actions:=HFlowContainer.new();actions.add_theme_constant_override("h_separation",8);column.add_child(actions)
	var on_court:Variant=data.get("on_court")
	var civ_id:=String(p.civ_id)
	if on_court is Callable: Kit.button(actions,"Send word",false,func()->void: (on_court as Callable).call(civ_id),"Open the court to receive their envoy or send ours")
	return card

func _feeling(view:Dictionary)->Control:
	var id:=String(view.id)
	var value:=float(view.value)
	var cell:=VBoxContainer.new()
	cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation",2)
	cell.mouse_filter=Control.MOUSE_FILTER_PASS
	cell.tooltip_text="%s %d%%: %s.\nWhy: %s." % [String(view.name),roundi(value*100.0),String(view.means),String(view.why)]
	var head:=HBoxContainer.new();head.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(head)
	var name:=Kit.label(head,String(view.name),"body",Color(0,0,0,0),false);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var amount:=Kit.label(head,"%d%%" % roundi(value*100.0),"value",Color(0,0,0,0),false);amount.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var meter:=Meter.new()
	meter.set_value(value,{"allure":T.TEAL,"awe":T.GOLD,"fear":T.RED,"respect":T.BLUE,"trust":T.GREEN,"resentment":T.RED}.get(id,T.GOLD))
	cell.add_child(meter)
	return cell

# ------------------------------------------------------------ our own people

func _fill_home()->void:
	_clear(home)
	var h:Dictionary=data.get("home",{})
	Kit.label(home,"Our own people","kicker")
	var card:=_card(T.GREEN)
	home.add_child(card)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);card.add_child(column)
	var row:=HFlowContainer.new();row.alignment=FlowContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("h_separation",26);row.add_theme_constant_override("v_separation",12);column.add_child(row)
	var pride:=float(h.get("pride",0.5))
	var trust:=float(h.get("trust",0.5))
	row.add_child(_medallion("Pride",pride,T.GREEN,"proud" if pride>=0.62 else ("ashamed" if pride<0.42 else "ordinary"),"How proud our people are of who they are: %s." % String(h.get("pride_why",""))))
	row.add_child(_medallion("Love of you",float(h.get("love",0.5)),T.GOLD,_band(float(h.get("love",0.5))),"How much our people love their god."))
	row.add_child(_medallion("Dread of you",float(h.get("dread",0.0)),T.RED,_band(float(h.get("dread",0.0))),"How much our people dread their god's wrath."))
	row.add_child(_medallion("Trust in chiefs",trust,T.TEAL,_band(trust),"How much our people trust those who lead them."))
	if String(h.get("regard_words",""))!="":
		var said:=_voice(column,_sentence(String(h.regard_words))+".",18)
		said.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var effects:Dictionary=h.get("effects",{})
	var parts:PackedStringArray=[]
	for pair:Array in [["attraction","how much families want to join us and stay"],["cohesion","how well we hold together"],["legitimacy","trust in the chiefs"],["menace","our warbands put off newcomers"]]:
		var amount:=float(effects.get(String(pair[0]),0.0))
		if absf(amount)<0.05: continue
		parts.append("%s %s%.1f" % [String(pair[1]),"+" if amount>0.0 else "−",absf(amount)])
	var note:=Kit.label(column,("This month, in points of 100: "+"; ".join(parts)+".") if not parts.is_empty() else "Pride is ordinary this month: it neither draws people to us nor holds them.","note")
	note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var forgiving:=float(effects.get("forgiveness",0.0))
	if absf(forgiving)>=0.02:
		var said:=("A proud people forgives: the blame its chiefs carry for hard orders, constant change and failed aims is %d%% lighter." % roundi(forgiving*100.0)) if forgiving>0.0 else ("A people ashamed of itself blames its chiefs %d%% more for hard orders, constant change and failed aims." % roundi(-forgiving*100.0))
		var line:=Kit.label(column,said,"note",T.GREEN if forgiving>0.0 else T.RED)
		line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

## First letter up, the rest as written.
static func _sentence(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if text!="" else text

static func _band(value:float)->String:
	if value<0.15: return "none"
	if value<0.35: return "a little"
	if value<0.6: return "some"
	if value<0.8: return "much"
	return "great"

func _medallion(title:String,value:float,tint:Color,word:String,tip:String)->Control:
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	column.mouse_filter=Control.MOUSE_FILTER_PASS
	column.tooltip_text=tip
	var gauge:=Medallion.new();gauge.set_value(value,tint);column.add_child(gauge)
	var name:=Kit.label(column,title,"heading",Color(0,0,0,0),false);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var said:=Kit.label(column,word,"note",Color(0,0,0,0),false);said.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;said.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return column
